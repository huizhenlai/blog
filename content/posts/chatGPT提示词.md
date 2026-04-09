---
title: "ChatGPT提示词及使用方法"
summary: Describe the template files
date: 2025-04-07
draft: true
weight: 6
tags: []  # 标签，可以是多个
categories: ["Tutorials"]  # 分类
author: "lhz"  # 作者
math: true
series: ["工具与工作流"]
hideTitle: true
---

# Instruction tuned LLMs

Two types of large language models (LLMs)

1. Base LLM: Predicts next word, based on text training data （完型填空）
2. Instruction Tuned LLM: Tries to follow instructions. Fine-tune on instructions and good attempts at following those instructions. -> **Helpful, Honest, Harmless** （满足要求，例如问答系统等等）



Giving instructions to someone that's smart but doesn't know the specifics of your task.



## Guidelines

1. Write clear and specific instructions.
   1. Use delimiters
   2. Ask for structured output
   3. Check whether conditions are satisfied
   4. Few-shot prompting ( give successful examples)
2. Give model time to think
   1. Specify the steps to complete a task
   2. 
