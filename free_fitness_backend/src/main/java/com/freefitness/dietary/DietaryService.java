package com.freefitness.dietary;

import com.freefitness.common.service.FileStorageService;
import com.freefitness.dietary.dto.DailySummary;
import com.freefitness.dietary.entity.*;
import com.freefitness.dietary.repository.*;
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
        List<DailyFoodItem> items = itemRepo.findByUserIdAndDateOrderByGmtCreateAsc(userId, date);
        Map<String, List<DailyFoodItem>> byMeal = items.stream()
                .collect(Collectors.groupingBy(DailyFoodItem::getMealCategory));

        List<DailySummary.MealSummary> meals = byMeal.entrySet().stream().map(entry -> {
            String cat = entry.getKey();
            List<DailyFoodItem> mealItems = entry.getValue();
            double[] macros = calculateMacros(mealItems);
            return new DailySummary.MealSummary(cat, macros[0], macros[1], macros[2], macros[3], mealItems.size());
        }).sorted(Comparator.comparing(DailySummary.MealSummary::getMealCategory))
          .collect(Collectors.toList());

        double[] totals = calculateMacros(items);
        double totalSodium = items.stream().mapToDouble(item -> {
            ServingInfo si = servingInfoRepo.findById(item.getServingInfoId()).orElse(null);
            if (si == null) return 0;
            double ratio = item.getFoodIntakeSize() / si.getServingSize();
            return si.getSodium() * ratio;
        }).sum();

        double totalWater = items.stream()
                .mapToDouble(i -> i.getWater() != null ? i.getWater() : 0.0)
                .sum();

        return new DailySummary(date, totals[0], totals[1], totals[2], totals[3], totalSodium, totalWater, meals);
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
