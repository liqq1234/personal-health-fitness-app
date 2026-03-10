package com.freefitness.dietary;

import com.freefitness.common.service.FileStorageService;
import com.freefitness.dietary.dto.DailySummary;
import com.freefitness.dietary.entity.*;
import com.freefitness.dietary.repository.*;
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

        return new DailySummary(date, totals[0], totals[1], totals[2], totals[3], totalSodium, meals);
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
}
