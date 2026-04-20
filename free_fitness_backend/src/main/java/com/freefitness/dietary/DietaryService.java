package com.freefitness.dietary;

import com.freefitness.common.service.FileStorageService;
import com.freefitness.dietary.dto.DailySummary;
import com.freefitness.dietary.entity.*;
import com.freefitness.dietary.repository.*;
import com.freefitness.health.entity.DietLog;
import com.freefitness.health.repository.DietLogRepository;
import com.freefitness.user.entity.User;
import com.freefitness.user.repository.UserRepository;
import com.freefitness.dietary.dto.NutritionAnalysis;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 饮食管理服务：食物库 / 营养素规格 / 每日条目 / 汇总 / 餐次照片
 */
@Service
@RequiredArgsConstructor
public class DietaryService {

    private final FoodRepository foodRepo;
    private final ServingInfoRepository servingInfoRepo;
    private final DailyFoodItemRepository itemRepo;
    private final MealPhotoRepository photoRepo;
    private final FileStorageService storageService;
    private final UserRepository userRepo;
    private final AiDietaryService aiService;
    private final DietLogRepository simplifiedDietRepo;

    @Value("${storage.meal-photo-dir}")
    private String mealPhotoDir;

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");
    private static final DateTimeFormatter D  = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    // ──────── 4.2 食物库 ────────

    public Page<Food> searchFoods(String category, String keyword, int page, int size) {
        return foodRepo.search(category, keyword, PageRequest.of(page, size));
    }

    public Food getFood(Long foodId) {
        return foodRepo.findById(foodId)
                .filter(f -> !Boolean.TRUE.equals(f.getIsDeleted()))
                .orElseThrow(() -> new IllegalArgumentException("食物不存在：" + foodId));
    }

    @Transactional
    public Food createFood(Food req) {
        req.setFoodId(null);
        req.setIsDeleted(false);
        req.setGmtCreate(LocalDateTime.now().format(DT));
        if (req.getContributor() == null) req.setContributor("user");
        return foodRepo.save(req);
    }

    @Transactional
    public Food updateFood(Long foodId, Food req) {
        Food existing = getFood(foodId);
        if ("system".equalsIgnoreCase(existing.getContributor())) {
            throw new IllegalArgumentException("系统食物不可修改");
        }
        req.setFoodId(foodId);
        req.setIsDeleted(false);
        req.setGmtCreate(existing.getGmtCreate());
        return foodRepo.save(req);
    }

    @Transactional
    public void softDeleteFood(Long foodId) {
        Food existing = getFood(foodId);
        if ("system".equalsIgnoreCase(existing.getContributor())) {
            throw new IllegalArgumentException("系统食物不可删除");
        }
        existing.setIsDeleted(true);
        foodRepo.save(existing);
    }

    // ──────── 4.3 营养素规格 ────────

    public List<ServingInfo> getServingInfos(Long foodId) {
        return servingInfoRepo.findByFoodIdAndIsDeletedFalse(foodId);
    }

    @Transactional
    public ServingInfo addServingInfo(Long foodId, ServingInfo req) {
        req.setServingInfoId(null);
        req.setFoodId(foodId);
        req.setIsDeleted(false);
        req.setGmtCreate(LocalDateTime.now().format(DT));
        return servingInfoRepo.save(req);
    }

    @Transactional
    public void deleteServingInfo(Long servingInfoId) {
        ServingInfo si = servingInfoRepo.findById(servingInfoId)
                .orElseThrow(() -> new IllegalArgumentException("营养素规格不存在：" + servingInfoId));
        si.setIsDeleted(true);
        servingInfoRepo.save(si);
    }

    // ──────── 4.4 每日饮食条目 ────────

    public List<DailyFoodItem> getDailyItems(Long userId, String date, String mealCategory) {
        if (mealCategory != null) {
            return itemRepo.findByUserIdAndDateAndMealCategoryOrderByGmtCreateAsc(userId, date, mealCategory);
        }
        return itemRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, date);
    }

    @Transactional
    public DailyFoodItem addDailyItem(Long userId, DailyFoodItem req) {
        req.setDailyFoodItemId(null);
        req.setUserId(userId);
        if (req.getDate() == null) req.setDate(LocalDate.now().format(D));
        req.setGmtCreate(LocalDateTime.now().format(DT));
        return itemRepo.save(req);
    }

    @Transactional
    public DailyFoodItem updateDailyItem(Long userId, Long itemId, DailyFoodItem req) {
        DailyFoodItem existing = itemRepo.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("饮食条目不存在：" + itemId));
        if (!existing.getUserId().equals(userId)) {
            throw new IllegalArgumentException("无权修改他人数据");
        }
        req.setDailyFoodItemId(itemId);
        req.setUserId(userId);
        req.setGmtModified(LocalDateTime.now().format(DT));
        return itemRepo.save(req);
    }

    @Transactional(readOnly = true)
    public List<com.freefitness.dietary.dto.DailyItemDetail> getDailyItemsDetailRange(
            Long userId, String startDate, String endDate, String mealCategory) {

        List<DailyFoodItem> items;
        if (startDate != null && endDate != null) {
            items = itemRepo.findByUserIdAndDateBetweenOrderByGmtCreateAsc(userId, startDate, endDate);
        } else {
            // fallback to current date or just empty
            items = itemRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, LocalDate.now().format(D));
        }

        if (mealCategory != null) {
            items = items.stream()
                    .filter(i -> mealCategory.equals(i.getMealCategory()))
                    .collect(Collectors.toList());
        }

        return items.stream().map(i -> {
            Food f = foodRepo.findById(i.getFoodId()).orElse(null);
            ServingInfo s = servingInfoRepo.findById(i.getServingInfoId()).orElse(null);
            return new com.freefitness.dietary.dto.DailyItemDetail(i, f, s);
        }).collect(Collectors.toList());
    }

    @Transactional
    public void deleteDailyItem(Long userId, Long itemId) {
        DailyFoodItem existing = itemRepo.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("饮食条目不存在：" + itemId));
        if (!existing.getUserId().equals(userId)) {
            throw new IllegalArgumentException("无权删除他人数据");
        }
        itemRepo.deleteById(itemId);
    }

    // ──────── 4.5 每日营养汇总 ────────

    public DailySummary getDailySummary(Long userId, String date) {
        // 1. 获取详细条目 (Detailed Items)
        List<DailyFoodItem> detailedItems = itemRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, date);
        // 2. 获取简版记录 (Simplified Logs)
        List<DietLog> simplifiedLogs = simplifiedDietRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, date);

        // 按餐次分组聚合
        Map<String, List<DailyFoodItem>> detailedByMeal = detailedItems.stream()
                .collect(Collectors.groupingBy(DailyFoodItem::getMealCategory));
        Map<String, List<DietLog>> simplifiedByMeal = simplifiedLogs.stream()
                .collect(Collectors.groupingBy(DietLog::getCategory));

        Set<String> allCategories = new HashSet<>();
        allCategories.addAll(detailedByMeal.keySet());
        allCategories.addAll(simplifiedByMeal.keySet());

        List<DailySummary.MealSummary> meals = allCategories.stream().map(cat -> {
            List<DailyFoodItem> dItems = detailedByMeal.getOrDefault(cat, Collections.emptyList());
            List<DietLog> sLogs = simplifiedByMeal.getOrDefault(cat, Collections.emptyList());

            double[] dMacros = calculateMacros(dItems);
            double sCal = sLogs.stream().mapToDouble(l -> l.getCalories() != null ? l.getCalories() : 0).sum();
            double sProt = sLogs.stream().mapToDouble(l -> l.getProtein() != null ? l.getProtein() : 0).sum();
            double sFat = sLogs.stream().mapToDouble(l -> l.getFat() != null ? l.getFat() : 0).sum();
            double sCarb = sLogs.stream().mapToDouble(l -> l.getCarbs() != null ? l.getCarbs() : 0).sum();

            return new DailySummary.MealSummary(
                    cat,
                    round(dMacros[0] + sCal),
                    round(dMacros[1] + sProt),
                    round(dMacros[2] + sFat),
                    round(dMacros[3] + sCarb),
                    dItems.size() + sLogs.size()
            );
        }).sorted(Comparator.comparing(DailySummary.MealSummary::getMealCategory))
          .collect(Collectors.toList());

        // 计算总计
        double[] detailedTotals = calculateMacros(detailedItems);
        double totalLogCal = simplifiedLogs.stream().mapToDouble(l -> l.getCalories() != null ? l.getCalories() : 0).sum();
        double totalLogProt = simplifiedLogs.stream().mapToDouble(l -> l.getProtein() != null ? l.getProtein() : 0).sum();
        double totalLogFat = simplifiedLogs.stream().mapToDouble(l -> l.getFat() != null ? l.getFat() : 0).sum();
        double totalLogCarb = simplifiedLogs.stream().mapToDouble(l -> l.getCarbs() != null ? l.getCarbs() : 0).sum();
        double totalLogWater = simplifiedLogs.stream().mapToDouble(l -> l.getWater() != null ? l.getWater() : 0).sum();

        double totalSodium = detailedItems.stream().mapToDouble(item -> {
            ServingInfo si = servingInfoRepo.findById(item.getServingInfoId()).orElse(null);
            if (si == null) return 0;
            double ratio = item.getFoodIntakeSize() / si.getServingSize();
            return si.getSodium() * ratio;
        }).sum();

        double detailedWater = detailedItems.stream()
                .mapToDouble(i -> i.getWater() != null ? i.getWater() : 0.0)
                .sum();

        StringBuilder mealDesc = new StringBuilder();
        if (!detailedItems.isEmpty()) {
            mealDesc.append("详细记录: ");
            for (int i = 0; i < detailedItems.size(); i++) {
                DailyFoodItem item = detailedItems.get(i);
                Food f = foodRepo.findById(item.getFoodId()).orElse(null);
                String name = (f != null) ? (f.getBrand() + " " + f.getProduct()) : "未知";
                mealDesc.append(name).append("(").append(item.getFoodIntakeSize()).append("g)");
                if (i < detailedItems.size() - 1) mealDesc.append(", ");
            }
        }

        if (!simplifiedLogs.isEmpty()) {
            if (mealDesc.length() > 0) mealDesc.append("; ");
            mealDesc.append("快捷记录: ");
            for (int i = 0; i < simplifiedLogs.size(); i++) {
                com.freefitness.health.entity.DietLog log = simplifiedLogs.get(i);
                mealDesc.append(log.getFoodName());
                if (i < simplifiedLogs.size() - 1) mealDesc.append(", ");
            }

        }


        return new DailySummary(
                date,
                round(detailedTotals[0] + totalLogCal),
                round(detailedTotals[1] + totalLogProt),
                round(detailedTotals[2] + totalLogFat),
                round(detailedTotals[3] + totalLogCarb),
                round(totalSodium),
                round(detailedWater + totalLogWater),
                mealDesc.toString(),
                meals
        );
    }



    private double[] calculateMacros(List<DailyFoodItem> items) {
        double cal = 0, prot = 0, fat = 0, carb = 0;
        for (DailyFoodItem item : items) {
            ServingInfo si = servingInfoRepo.findById(item.getServingInfoId()).orElse(null);
            if (si == null) continue;
            double ratio = item.getFoodIntakeSize() / si.getServingSize();
            cal  += si.getEnergyKcal() != null ? si.getEnergyKcal() * ratio : si.getEnergy() * ratio / 4.184;
            prot += si.getProtein() * ratio;
            fat  += si.getTotalFat() * ratio;
            carb += si.getTotalCarbohydrate() * ratio;
        }
        return new double[]{round(cal), round(prot), round(fat), round(carb)};
    }

    private double round(double v) {
        return Math.round(v * 10.0) / 10.0;
    }

    // ──────── 4.6 餐次照片 ────────

    @Transactional
    public MealPhoto uploadMealPhoto(Long userId, String date, String mealCategory,
                                     MultipartFile file) throws IOException {
        String url = storageService.storeFile(file, mealPhotoDir, "/uploads/meal-photos/");

        List<MealPhoto> existing = photoRepo.findByUserIdAndDateAndMealCategory(userId, date, mealCategory);
        MealPhoto photo;
        if (!existing.isEmpty()) {
            photo = existing.get(0);
            String urls = photo.getPhotos();
            urls = urls.substring(0, urls.length() - 1) + ",\"" + url + "\"]";
            photo.setPhotos(urls);
        } else {
            photo = new MealPhoto();
            photo.setUserId(userId);
            photo.setDate(date);
            photo.setMealCategory(mealCategory);
            photo.setPhotos("[\"" + url + "\"]");
            photo.setGmtCreate(LocalDateTime.now().format(DT));
        }
        return photoRepo.save(photo);
    }

    public List<MealPhoto> getMealPhotos(Long userId, String date) {
        return photoRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, date);
    }

    public NutritionAnalysis getNutritionAnalysis(Long userId, String date) {
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        DailySummary summary = getDailySummary(userId, date);

        // Simple BMR (Mifflin-St Jeor)
        double targetCal = calculateTargetCalories(user);
        double targetProt = user.getProteinGoal() != null ? user.getProteinGoal() : (targetCal * 0.25 / 4);
        double targetFat = user.getFatGoal() != null ? user.getFatGoal() : (targetCal * 0.25 / 9);
        double targetCarbs = user.getChoGoal() != null ? user.getChoGoal() : (targetCal * 0.5 / 4);

        NutritionAnalysis analysis = NutritionAnalysis.builder()
                .date(date)
                .currentCalories(summary.getTotalCalories())
                .currentProtein(summary.getTotalProtein())
                .currentFat(summary.getTotalFat())
                .currentCarbs(summary.getTotalCarbs())
                .currentWater(summary.getTotalWater())
                .targetCalories(round(targetCal))
                .targetProtein(round(targetProt))
                .targetFat(round(targetFat))
                .targetCarbs(round(targetCarbs))
                .targetWater(user.getWaterGoal() != null ? user.getWaterGoal() : 2000.0)
                .recommendations(new ArrayList<>())
                .mealDescriptions(summary.getMealDescriptions())
                .build();


        analysis.setCalorieGap(round(analysis.getTargetCalories() - analysis.getCurrentCalories()));

        analysis.setProteinGap(round(analysis.getTargetProtein() - analysis.getCurrentProtein()));
        analysis.setFatGap(round(analysis.getTargetFat() - analysis.getCurrentFat()));
        analysis.setCarbsGap(round(analysis.getTargetCarbs() - analysis.getCurrentCarbs()));
        analysis.setWaterGap(round(analysis.getTargetWater() - analysis.getCurrentWater()));

        // 如果 AI 服务可用，生成更人性化的建议
        String aiAdvice = aiService.generateSuggestions(analysis);
        analysis.getRecommendations().add(aiAdvice);

        generateRecommendations(analysis);

        return analysis;
    }

    private double calculateTargetCalories(User user) {
        if (user.getRdaGoal() != null && user.getRdaGoal() > 0) return user.getRdaGoal();
        
        // Default BMR
        double weight = user.getCurrentWeight() != null ? user.getCurrentWeight() : 70.0;
        double height = user.getHeight() != null ? user.getHeight() : 170.0;
        int age = calculateAge(user.getDateOfBirth());
        
        double bmr;
        if ("Female".equalsIgnoreCase(user.getGender())) {
            bmr = 10 * weight + 6.25 * height - 5 * age - 161;
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * age + 5;
        }
        return bmr * 1.375; // Lightly active
    }

    private int calculateAge(String dob) {
        if (dob == null || dob.isEmpty()) return 25;
        try {
            LocalDate birthDate = LocalDate.parse(dob);
            return LocalDate.now().getYear() - birthDate.getYear();
        } catch (Exception e) {
            return 25;
        }
    }

    private void generateRecommendations(NutritionAnalysis analysis) {
        if (analysis.getProteinGap() > 10) {
            analysis.getRecommendations().add("蛋白质摄入不足，建议补充：鸡胸肉、牛肉、鸡蛋或蛋白粉。");
        }
        if (analysis.getFatGap() > 10) {
            analysis.getRecommendations().add("建议增加优质脂肪摄入：牛油果、坚果或橄榄油。");
        }
        if (analysis.getCarbsGap() > 30) {
            analysis.getRecommendations().add("碳水化合物缺口较大，可适当增加：燕麦、糙米或全麦面包。");
        }
        if (analysis.getCalorieGap() > 200) {
            analysis.setStatusSummary("能量摄入不足");
        } else if (analysis.getCalorieGap() < -200) {
            analysis.setStatusSummary("能量摄入过重");
        } else {
            analysis.setStatusSummary("营养均衡");
        }
    }
}
