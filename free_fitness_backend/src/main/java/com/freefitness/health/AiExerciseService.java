package com.freefitness.health;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiExerciseService {

    @Value("${deepseek.api-key}")
    private String apiKey;

    @Value("${deepseek.base-url}")
    private String baseUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    public String generateExerciseFeedback(String exerciseSummary, Map<String, Object> userProfile) {
        double height = (Double) userProfile.getOrDefault("height", 0.0);
        double weight = (Double) userProfile.getOrDefault("weight", 0.0);
        double bmi    = (Double) userProfile.getOrDefault("bmi", 0.0);
        Object age    = userProfile.getOrDefault("age", null);
        Object gender = userProfile.getOrDefault("gender", null);

        // 构建易于 AI 理解的用户资料描述（0 值改为"未填写"）
        String heightStr = height > 0 ? String.format("%.1fcm", height) : "未填写";
        String weightStr = weight > 0 ? String.format("%.1fkg", weight) : "未填写";
        String bmiStr    = bmi    > 0 ? String.format("%.1f", bmi)      : "未知";
        String ageStr    = age    != null ? age.toString() + "岁"        : "未填写";
        String genderStr = gender != null && !gender.toString().isBlank() ? gender.toString() : "未填写";

        String profileStr = String.format("用户个人资料：年龄 %s, 性别 %s, 身高 %s, 体重 %s, BMI %s。",
                ageStr, genderStr, heightStr, weightStr, bmiStr);

        String systemPrompt = """
                你是一名专业的运动健身教练。请结合用户的个人资料和过去两周的运动数据摘要，给出极其个性化的科学运动建议。
                
                分析原则：
                1. 身体形态：
                   - 如果 BMI > 24（偏胖）：重点建议多做有氧运动（游泳、快走、慢跑）以燃烧脂肪，并控制饮食。
                   - 如果 BMI < 18.5（偏瘦）：重点建议配合适量力量训练（增肌练习）并补充营养，避免过度消耗。
                2. 年龄策略：
                   - 年龄较大（>55岁）：避免过于剧烈的弹跳或高强度对抗运动，重点推荐太极、散步或水中运动，强调保护关节。
                   - 年龄较小（<18岁）：强调运动中的身体保护，避免过早进行极限负重训练，注意运动姿势和安全。
                3. 运动规律反馈：
                   - 坚持得好：给予热情的正向回馈。
                   - 偶尔断层：温和提醒，鼓励回归。
                   - 连续空白：警示体能退步和代谢下降风险。

                要求：
                - 语气专业、亲切、有感染力。
                - 必须整合用户的身体素质（BMI/年龄）和近期运动表现。
                - 语言简洁精炼，200字左右。
                - 请以专家身份直接给出建议，不要包含类似“有问题随时问我”、“随时为你服务”等引导对话或邀请互动的结尾，因为这里不是聊天界面。
                """;

        String userContent = profileStr + "\n" + exerciseSummary;

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", "deepseek-chat");
            requestBody.put("messages", List.of(
                    Map.of("role", "system", "content", systemPrompt),
                    Map.of("role", "user", "content", userContent)
            ));

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            Map<String, Object> response = restTemplate.postForObject(baseUrl + "/chat/completions", entity, Map.class);

            if (response != null && response.containsKey("choices")) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.get("choices");
                return (String) ((Map<String, Object>) choices.get(0).get("message")).get("content");
            }
        } catch (Exception e) {
            log.error("AI 生成运动建议出错: {}", e.getMessage());
        }

        return "近期运动规律稍显紊乱，身体是革命的本钱，建议合理安排时间，找回运动状态！";
    }
}
