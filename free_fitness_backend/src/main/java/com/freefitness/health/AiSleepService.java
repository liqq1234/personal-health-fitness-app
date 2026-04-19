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
                1. 睡眠时长：
                   - 理想时长为 7-9 小时。
                   - 长期不足（<6小时）：警示免疫力下降、记忆力减退和心血管风险，建议逐步提前入睡时间。
                2. 规律性：
                   - 入睡和起床时间是否规律。不规律会导致生物钟紊乱，建议建立固定的睡前仪式。
                3. 睡眠质量：
                   - 持续睡眠记为“好”，断断续续记为“不好”。
                   - 质量差：分析可能的原因（精神压力、环境因素等），建议睡前远离电子设备，尝试深呼吸或冥想。
                4. 年龄建议：
                   - 青少年：强调睡眠对生长发育的重要性。
                   - 中年人：关注压力对睡眠的影响。
                   - 老年人：关注浅睡眠问题，建议适量日间运动。

                要求：
                - 语气专业、亲切、富有同理心。
                - 整合用户的睡眠时长、规律性和质量表现。
                - 给出具体的调整建议（如：睡前温水澡、固定晨起时间等）。
                - 语言简洁精炼，200字左右。
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
