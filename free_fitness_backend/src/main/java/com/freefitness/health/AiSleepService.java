package com.freefitness.health;

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
public class AiSleepService {

    @Value("${deepseek.api-key}")
    private String apiKey;

    @Value("${deepseek.base-url}")
    private String baseUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    public String generateSleepFeedback(String sleepSummary, Map<String, Object> userProfile) {
        String profileStr = String.format("用户个人资料：年龄 %s, 性别 %s。",
                userProfile.getOrDefault("age", "未知"),
                userProfile.getOrDefault("gender", "未知"));

        String systemPrompt = """
                你是一名专业的睡眠健康专家。请结合用户的个人资料和过去两周的睡眠数据摘要，给出极其个性化的睡眠改善建议。
                
                分析原则：
                1. 睡眠时长与模式持续性：
                   - 理想时长为 7-9 小时。
                   - 特别关注“连续满 8 小时天数”：若该数值较高（如 >= 7天），说明用户具有极强的睡眠纪律，请给予肯定。
                2. 规律性与入睡时间：
                   - 观察“平均入睡时间点”。建议在晚上 11 点前入睡。若入睡点较晚或波动大，即使时长补足，也不利于深度修复。
                3. 质量评估推断：
                   - 如果缺乏显式质量评分，请基于“时长稳定性”和“入睡点”自主判断其睡眠质量（如：长期稳定且充足记为“优”；波动大且短记为“警示”）。
                4. 环境与习惯分析：
                   - 结合“习惯备注”中的具体描述（如压力大、睡前运动等），深度分析潜在的睡眠障碍或积极因素。

                要求：
                - 语气专业、亲切、富有同理心。
                - 整合分析用户的时长、模式持续性、入睡规律和个性化备注。
                - 给出具体的、可操作的调整建议。
                - 语言精炼，控制在 250 字左右。
                - 请以专家身份直接给出建议，不要包含任何引导对话或邀请互动的结尾，因为这里不是聊天界面。
                """;


        String userContent = profileStr + "\\n" + sleepSummary;

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
            log.error("AI 生成睡眠建议出错: {}", e.getMessage());
        }

        return "近期睡眠规律稍显紊乱，保证充足的休息是精力的源泉，建议调整作息，拥抱高质睡眠！";
    }
}
