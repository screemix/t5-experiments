#!/usr/bin/env bash
# CUDA_VISIBLE_DEVICES=1,2 NP=2 ./test_bert_sparse_pretrain_train_valid.sh
set -e
cd ..

CUBLAS_WORKSPACE_CONFIG=:4096:2
CUDA_LAUNCH_BLOCKING=1

MODEL_NAME=facebook/bart-base
MODEL_TYPE=encoder-decoder
MODEL_CLS=transformers:BartForConditionalGeneration
TASK_NAME=gov_report
PREFIX="summarize: "

# BART 256 512 1024
# LED 1024 4096 16384
SRC_LEN=256
# BART 1024
# LED 1024
# 
TGT_LEN=1024

SCHEDULER=constant_with_warmup
METRIC=rouge/geometric_mean

for LR in 1e-04 5e-05
do
for N in 1 2
do
horovodrun --gloo -np $NP python run_finetuning_scrolls.py \
        --task_name $TASK_NAME \
        --model_path ./runs/finetune/$MODEL_NAME/$TASK_NAME/lr${LR}_${SCHEDULER}_adamw_wd1e-03_${SRC_LEN}-${TGT_LEN}/run_$N \
        --from_pretrained $MODEL_NAME \
        --model_type $MODEL_TYPE \
        --model_cls $MODEL_CLS \
        --use_generate_on_valid \
        --input_seq_len $SRC_LEN \
        --target_seq_len $TGT_LEN \
        --batch_size 2 --gradient_accumulation_steps 4 \
        --save_best --iters 5000 \
        --optimizer AdamW  --weight_decay 0.001 \
        --lr ${LR} --lr_scheduler $SCHEDULER --num_warmup_steps 100 \
        --data_n_workers 2 \
        --log_interval 100 --valid_interval 200 \
        --optimize_metric $METRIC --optimize_mode max \
        --seed $(($N+42)) \
        --clip_grad_value 5.0
done
done
echo "run_bert_pretraining.py done"
echo "done"
