package com.freefitness.dietary;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.freefitness.dietary.dto.AiParseResponse;
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
public class AiDietaryService {

    @Value("${deepseek.api-key}")
    private String apiKey;

    @Value("${deepseek.base-url}")
    private String baseUrl;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 调用 DeepSeek AI 模糊识别逻辑
     * 识别自然语言中的食物摄入，并分解为详细的营养成分
     */
    public AiParseResponse parseText(String text) {
        String systemPrompt = """
                你是一名资深的营养学家。请分析用户的饮食描述，提取出具体的食物项、摄入量（克/g），并计算其营养成分（热量(kcal)、蛋白质(g)、碳水(g)、脂肪(g)）。
                格式要求：
                1. 必须返回纯 JSON 格式。
                2. 结构必须符合：{"foods":[{"foodName":"xx","amount":300,"unit":"g","calories":240,"protein":12,"carbs":18,"fat":14}],"totalCalories":240,"totalProtein":12,"totalCarbs":18,"totalFat":14,"totalWater":0}
                3. 如果是组合菜品（如番茄炒鸡蛋），请尝试将其分解或按整体标准估算。
                4. 请务必客观真实。
                """;

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", "deepseek-chat");
            requestBody.put("messages", List.of(
                    Map.of("role", "system", "content", systemPrompt),
                    Map.of("role", "user", "content", text)
            ));
            // 强制要求 JSON 模式 (如果平台支持)
            Map<String, String> responseFormat = new HashMap<>();
            responseFormat.put("type", "json_object");
            requestBody.put("response_format", responseFormat);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            Map<String, Object> response = restTemplate.postForObject(baseUrl + "/chat/completions", entity, Map.class);

            if (response != null && response.containsKey("choices")) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.get("choices");
                String content = (String) ((Map<String, Object>) choices.get(0).get("message")).get("content");
                
                // 去除可能存在的 markdown 标记
                content = content.replace("```json", "").replace("```", "").trim();
                
                AiParseResponse result = objectMapper.readValue(content, AiParseResponse.class);
                result.setOriginalText(text);
                return result;
            }
        } catch (Exception e) {
            log.error("AI 识别出错: {}", e.getMessage());
        }

        // 兜底返回空结果或简单模拟
        return fallbackParse(text);
    }

    /**
     * 调用 AI 针对当天的摄入数据和目标缺口生成个性化建议
     */
    public String generateSuggestions(com.freefitness.dietary.dto.NutritionAnalysis analysis) {
        String systemPrompt = """
                你是一名资深的营养咨询专家。请根据用户当天的饮食摄入数据和设定的目标，给出专业的、温和的、具有可操作性的饮食改进建议。
                注意点：
                1. 语气必须亲切友好。
                2. 针对能量(Calories)、蛋白质(Protein)、碳水(Carbs)、脂肪(Fat)和水分(Water)的缺口给出具体建议。
                3. 如果水分摄入不足，必须特别提醒多喝水。
                4. 请分点阐述建议（1, 2, 3...）。
                5. 保持简洁，字数控制在200字以内。
                """;

        String userIntake = String.format(
                "今日摄入实况：热量 %.1f kcal (目标 %.1f), 蛋白质 %.1f g (目标 %.1f), 碳水 %.1f g (目标 %.1f), 脂肪 %.1f g (目标 %.1f), 水分 %.1f ml (目标 %.1f)。",
                analysis.getCurrentCalories(), analysis.getTargetCalories(),
                analysis.getCurrentProtein(), analysis.getTargetProtein(),
                analysis.getCurrentCarbs(), analysis.getTargetCarbs(),
                analysis.getCurrentFat(), analysis.getTargetFat(),
                analysis.getCurrentWater(), analysis.getTargetWater()
        );

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", "deepseek-chat");
            requestBody.put("messages", List.of(
                    Map.of("role", "system", "content", systemPrompt),
                    Map.of("role", "user", "content", userIntake)
            ));

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            Map<String, Object> response = restTemplate.postForObject(baseUrl + "/chat/completions", entity, Map.class);

            if (response != null && response.containsKey("choices")) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.get("choices");
                return (String) ((Map<String, Object>) choices.get(0).get("message")).get("content");
            }
        } catch (Exception e) {
            log.error("AI 生成建议出错: {}", e.getMessage());
        }

        return "基于当前数据，建议保持均衡饮食，多喝水，多吃新鲜果蔬。";
    }

    private AiParseResponse fallbackParse(String text) {
        AiParseResponse resp = new AiParseResponse();
        resp.setOriginalText(text);
        // 原有的简单 mock 逻辑作为兜底
        if (text.contains("番茄炒鸡蛋")) {
            resp.setFoods(List.of(new AiParseResponse.ParsedFood("番茄炒鸡蛋", 300, "g", 240, 12, 18, 14)));
            resp.setTotalCalories(240);
            resp.setTotalProtein(12);
            resp.setTotalCarbs(18);
            resp.setTotalFat(14);
        }
        return resp;
    }
}
