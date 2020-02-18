#!/bin/bash

# Overview
# --------
# This is a script that converts MOSES models into Atomese in Scheme code,
# based on the description detailed in "doc/learned-model-to-atomese.md".
#
# Usage
# -----
# To print the usage, run it without argument.
#
# An example usage:
#
# ./moses2atomese.sh comboResultsFull.csv longevity -m mosesDoseNoFeature2Gene.csv -o combo_results_full.scm

set -u                          # raise error on unknown variable read
# set -x                          # debug trace

####################
# Program argument #
####################

if [[ $# == 0 || $# -gt 8 ]]; then
    echo "Usage: $0 MODEL_RESULT_FILE PRED_NAME [-m FEATURE_GENE_MAP] [-o OUTPUT_FILE] [-s SCORES_FILE]"
    echo "Example: $0 moses_raw_results.csv \"longevity\" -m feature2gene.csv -o moses.scm -s scores.csv"
    exit 1
fi

readonly MODEL_RESULT_FILE="$1"
readonly PRED_NAME="$2"
FEATURE_GENE_MAP=""
OUTPUT_FILE="/dev/stdout"
SCORES_FILE=""

shift 2
while getopts "m:o:s:" opt; do
    case $opt in
        m) FEATURE_GENE_MAP=$OPTARG
            ;;
        o) OUTPUT_FILE=$OPTARG
            ;;
        s) SCORES_FILE=$OPTARG
            ;;
    esac
done

#############
# Functions #
#############

# Do arithmetic through the use of bc, with a scale fixed at 5
bcl() {
    echo "scale=5; $1" | bc -l
}

# Given a count, convert it to a TV confidence
count2confidence() {
    local k=800
    local c=$1
    bcl "$c/($c+$k)"
}

# Given a CSV file with two columns:
#
# 1. name of a feature
#
# 2. name of a gene
#
# create an associative array that maps the name of a feature to the name
# of a gene.
declare -A feature_gene_map
populate_feature_gene_map() {
    while IFS=',' read feature gene rest
    do
        feature_gene_map[$feature]=$gene
    done < $1
}

# Given a CSV file containing the scores like accuracy, precision etc for
# each MOSES model, create an associative array that maps the model with
# all of the scores provided.
declare -A model_scores_map
populate_model_score_map() {
    # Get all the columns from the first row
    IFS=',' read -ra score_columns <<< $(head -n 1 $1)

    # Read the scores from the rest of the rows
    while IFS=',' read model scores
    do
        model_scores_map[$model]=$scores
    done <<< $(tail -n +2 $1)
}

# Given a CSV file containing the results for each MOSES models, in the
# format of:
#
# - Row 1 being the name of the columns
#
# - Row 2 being the case (the actual results)
#
# - Rest of the rows being the results of the models
#
# create associative arrays that maps the the model with its corresponding
# true positive, false positive, true negative, and false negative values.
declare -A model_tp_map
declare -A model_fp_map
declare -A model_tn_map
declare -A model_fn_map
populate_model_result_map() {
    local csv_file=$1

    # Get the actual results from the 2nd row of the file
    local actual_results
    while IFS=',' read first_col results
    do
        IFS=',' read -ra actual_results <<< $results
    done <<< $(sed -n 2p $csv_file)

    # Read the results from the rest of the rows, and get the
    # TP, FP, TN, and FN values
    while IFS=',' read model results
    do
        local tp=0
        local fp=0
        local tn=0
        local fn=0

        IFS=',' read -ra model_results <<< $results

        for i in "${!model_results[@]}"
        do
            if [ ${actual_results[$i]} == "1" ] && [ ${model_results[$i]} == "1" ]
            then
                ((++tp))
            fi

            if [ ${actual_results[$i]} == "0" ] && [ ${model_results[$i]} == "1" ]
            then
                ((++fp))
            fi

            if [ ${actual_results[$i]} == "0" ] && [ ${model_results[$i]} == "0" ]
            then
                ((++tn))
            fi

            if [ ${actual_results[$i]} == "1" ] && [ ${model_results[$i]} == "0" ]
            then
                ((++fn))
            fi
        done

        model_tp_map[$model]=$tp
        model_fp_map[$model]=$fp
        model_tn_map[$model]=$tn
        model_fn_map[$model]=$fn

    done <<< $(tail -n +3 $csv_file)
}

# Given a MOSES model (in string), like:
#
#     or($X1.1666251_G.A_h $X1.1666251_G.A)
#
# along with:
#
# 1. a TV strength for the model
#
# 2. a TV confidence for the model
#
# return a Scheme code representing the Atomese, like:
#
#     (Or (Predicate "$X1.1666251_G.A_h") (Predicate "$X1.1666251_G.A"))
#
# with the corresponding TV assigned to the root operator of the model
moses2atomese() {
    local model_str=$1
    local tv_strength=$2
    local tv_conf=$3

    links=$(echo $model_str | sed -e 's/or(/(OrLink /g' \
                                  -e 's/and(/(AndLink /g' \
                                  -e 's/\(\$X[._ATCGh{0-9}]\+\)/(PredicateNode \"\1\")/g')

    # Seems easier to handle the NotLinks separately after the above
    links=$(echo $links | sed -e 's/!\([^)]*\)/(NotLink \1)/g')

    # Assign the TV to the root operator, or the PredicateNode if it's just a
    # single feature
    [[ $links == \(PredicateNode* ]] && \
        echo $links | sed -e "s/)/ (stv $tv_strength $tv_conf))/" || \
        echo $links | sed -e "s/ (/ (stv $tv_strength $tv_conf) (/"
}

# Given
#
# 1. a predicate name
#
# 2. a combo model
#
# 3. a sensitivity value (TV strength) for the implication
#
# 4. a TV confidence for the implication
#
# 5. a TV strength for the predicate
#
# 6. a TV confidence for the predicate
#
# return a Scheme code defining the implication between the predicate
# and the model:
#
# ImplicationLink (stv {3} {4})
#     PredicateNode {1} (stv {5} {6})
#     {2}
implication_sensitivity() {
    local pred=$1
    local model=$2
    local sensitivity=$3
    local impli_conf=$4
    local pred_strength=$5
    local pred_conf=$6
    cat <<EOF
(ImplicationLink (stv $sensitivity $impli_conf)
    (PredicateNode "$pred" (stv $pred_strength $pred_conf))
    $model)
EOF
}

# Given
#
# 1. a predicate name
#
# 2. a combo model
#
# 3. a specificity value (TV strength) for the implication
#
# 4. a TV confidence for the implication
#
# 5. a TV strength for the predicate
#
# 6. a TV confidence for the predicate
#
# 7. a TV strength for the negation of the predicate
#
# 8. a TV confidence for the negation of the predicate
#
# 9. a TV strength for the negation of the model
#
# 10. a TV confidence for the negation of the model
#
# return a Scheme code defining the implication between the predicate
# and the model:
#
# ImplicationLink (stv {3} {4})
#     NotLink (stv {7} {8})
#         PredicateNode {1} (stv {5} {6})
#     NotLink (stv {9} {10})
#         {2}
implication_specificity() {
    local pred=$1
    local model=$2
    local specificity=$3
    local impli_conf=$4
    local pred_strength=$5
    local pred_conf=$6
    local neg_pred_strength=$7
    local neg_pred_conf=$8
    local neg_model_strength=$9
    local neg_model_conf=${10}
    cat <<EOF
(ImplicationLink (stv $specificity $impli_conf)
    (NotLink (stv $neg_pred_strength $neg_pred_conf)
        (PredicateNode "$pred" (stv $pred_strength $pred_conf)))
    (NotLink (stv $neg_model_strength $neg_model_conf)
        $model))
EOF
}

# Given
#
# 1. a predicate name
#
# 2. a combo model
#
# 3. a precision value (TV strength) for the implication
#
# 4. a TV confidence for the implication
#
# 5. a TV strength for the predicate
#
# 6. a TV confidence for the predicate
#
# return a Scheme code defining the implication between the predicate
# and the model:
#
# ImplicationLink (stv {3} {4})
#     {2}
#     PredicateNode {1} (stv {5} {6})
implication_precision() {
    local pred=$1
    local model=$2
    local precision=$3
    local impli_conf=$4
    local pred_strength=$5
    local pred_conf=$6
    cat <<EOF
(ImplicationLink (stv $precision $impli_conf)
    $model
    (PredicateNode "$pred" (stv $pred_strength $pred_conf)))
EOF
}

# Given
#
# 1. a predicate name
#
# 2. a combo model
#
# 3. a negative predictive value (TV strength) for the implication
#
# 4. a TV confidence for the implication
#
# 5. a TV strength for the predicate
#
# 6. a TV confidence for the predicate
#
# 7. a TV strength for the negation of the predicate
#
# 8. a TV confidence for the negation of the predicate
#
# 9. a TV strength for the negation of the model
#
# 10. a TV confidence for the negation of the model
#
# return a Scheme code defining the implication between the predicate
# and the model:
#
# ImplicationLink (stv {3} {4})
#     NotLink (stv {9} {10})
#         PredicateNode {1} (stv {5} {6})
#     NotLink (stv {7} {8})
#         {2}
implication_neg_pred_val() {
    local pred=$1
    local model=$2
    local npv=$3
    local impli_conf=$4
    local pred_strength=$5
    local pred_conf=$6
    local neg_pred_strength=$7
    local neg_pred_conf=$8
    local neg_model_strength=$9
    local neg_model_conf=${10}
    cat <<EOF
(ImplicationLink (stv $npv $impli_conf)
    (NotLink (stv $neg_model_strength $neg_model_conf)
        $model)
    (NotLink (stv $neg_pred_strength $neg_pred_conf)
        (PredicateNode "$pred" (stv $pred_strength $pred_conf))))
EOF
}

# Given
#
# 1. a predicate name (i.e. the feature)
#
# 2. a gene name
#
# return a Scheme code defining the equivalence between the predicate
# and its corresponding gene:
#
# EquivalenceLink (stv 1 1)
#     PredicateNode {1}
#     ExecutionOutputLink
#         GroundedSchemaNode "scm: make-has-{heterozygous|homozygous}-SNP-predicate"
#         GeneNode {2}
equivalence_feature_gene() {
    local pred=$1
    local gene=$2
    [[ $pred == *_h ]] && local zygous="heterozygous" || local zygous="homozygous"
    cat <<EOF
(EquivalenceLink (stv 1 1)
    (PredicateNode "$pred")
    (ExecutionOutputLink
        (GroundedSchemaNode "scm: make-has-$zygous-SNP-predicate")
        (GeneNode "$gene")))
EOF
}

########
# Main #
########

# Get the raw results, calculate the numbers needed for the confusion matrix
echo "Reading $MODEL_RESULT_FILE ..."
populate_model_result_map $MODEL_RESULT_FILE

# Get the mapping between the features and the genes
if [[ -z $FEATURE_GENE_MAP ]]
then
    echo "[WARN] No feature-gene mapping available, skipping EquivalenceLink generation..."
else
    echo "Reading $FEATURE_GENE_MAP ..."
    populate_feature_gene_map $FEATURE_GENE_MAP
fi

# Get the models and their scores
if [[ ! -z $SCORES_FILE ]]
then
    echo "Reading $SCORES_FILE ..."
    populate_model_score_map $SCORES_FILE
fi

# Generate Atomese in Scheme
echo "Generating Atomese ..."
while IFS=',' read model rest
do
    echo ";; ===== For MOSES model: $model"

    # Calculate all the needed values
    tp=${model_tp_map[$model]}
    fp=${model_fp_map[$model]}
    tn=${model_tn_map[$model]}
    fn=${model_fn_map[$model]}
    p=$(($tp + $fn))
    n=$(($fp + $tn))
    m=$(($p + $n))
    pred_tv_strength=$(bcl "$p/$m")
    pred_tv_conf=$(count2confidence $m)

    # Generate the MOSES model and assign TV to it
    moses_model=$(moses2atomese "$model" \
                                $(bcl "($tp+$fp)/$m") \
                                $(count2confidence $m))

    # Then generate all the implications we want
    implication_sensitivity \
        "$PRED_NAME" \
        "$moses_model" \
        $(bcl "$tp/$p") \
        $(count2confidence $p) \
        $pred_tv_strength \
        $pred_tv_conf

    implication_specificity \
        "$PRED_NAME" \
        "$moses_model" \
        $(bcl "$tn/$n") \
        $(count2confidence $n) \
        $pred_tv_strength \
        $pred_tv_conf \
        $(bcl "$n/$m") \
        $(count2confidence $m) \
        $(bcl "($fn+$tn)/$m") \
        $(count2confidence $m)

    implication_precision \
        "$PRED_NAME" \
        "$moses_model" \
        $(bcl "$tp/($tp+$fp)") \
        $(count2confidence $(bcl "$tp+$fp")) \
        $pred_tv_strength \
        $pred_tv_conf

    implication_neg_pred_val \
        "$PRED_NAME" \
        "$moses_model" \
        $(bcl "$tn/($tn+$fn)") \
        $(count2confidence $(bcl "$tn+$fn")) \
        $pred_tv_strength \
        $pred_tv_conf \
        $(bcl "$n/$m") \
        $(count2confidence $m) \
        $(bcl "($fn+$tn)/$m") \
        $(count2confidence $m)

    # ... and an additional one to connect the features exist in the model
    # to the names of the genes
    if [[ ! -z $FEATURE_GENE_MAP ]]
    then
        # The format is, e.g. $X1.1666251_G.A
        for feature in $(echo $model | grep -o "\$X[._ATCGh0-9]\+")
        do
            # Some pre-processing to make sure the format is consistant with the
            # feature-gene mapping that we got from the file, here it tries to
            # turn, for example, "$X1.1666251_G.A_h" into "1:1666251_G/A"
            ## 1. Remove the "$", if any
            ## 2. Remove "X" and the digits following it, if any
            ## 3. Turn the first "." into a ":", if any
            ## 4. Turn the last "." into a "/", if any
            ## 5. Remove "_h" at the end of the feature, if any
            feature_reformatted=$(echo $feature | sed -e 's/\$//' \
                                                      -e "s/X\([0-9]\+\)/\1/" \
                                                      -e "s/\./:/" \
                                                      -e "s/\./\//" \
                                                      -e "s/_h//")

            # There may be a version number appended at the end of the name of a gene,
            # for example, the ".8" as in "RP1-283E3.8", which is not necessary for our
            # purpose, so can and should be removed
            gene=$(echo "${feature_gene_map[$feature_reformatted]}" | sed -r "s/\.[0-9]+//")

            # Finally, generate the EquivalenceLink Atomese
            equivalence_feature_gene "$feature" "$gene"
        done
    fi
done <<< $(tail -n +3 $MODEL_RESULT_FILE) > "$OUTPUT_FILE"
