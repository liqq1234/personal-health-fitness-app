package com.freefitness.config;

import com.freefitness.dietary.entity.Food;
import com.freefitness.dietary.entity.ServingInfo;
import com.freefitness.dietary.repository.FoodRepository;
import com.freefitness.dietary.repository.ServingInfoRepository;
import com.freefitness.training.entity.Exercise;
import com.freefitness.training.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * 数据库种子初始化：注入内置食物和动作
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DatabaseSeeder implements CommandLineRunner {

    private final FoodRepository foodRepo;
    private final ServingInfoRepository servingRepo;
    private final ExerciseRepository exerciseRepo;

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    @Override
    public void run(String... args) {
        if (foodRepo.count() == 0) {
            initFoods();
        }
        if (exerciseRepo.count() == 0) {
            initExercises();
        }
    }

    private void initFoods() {
        log.info("初始化内置食物库...");
        
        // 1. 米饭
        Food rice = new Food();
        rice.setBrand("系统");
        rice.setProduct("白米饭");
        rice.setCategory("主食");
        rice.setContributor("system");
        rice.setIsDeleted(false);
        rice.setGmtCreate(LocalDateTime.now().format(FMT));
        rice = foodRepo.save(rice);

        ServingInfo rSi = new ServingInfo();
        rSi.setFoodId(rice.getFoodId());
        rSi.setServingSize(100);
        rSi.setServingUnit("克");
        rSi.setEnergy(544.0);
        rSi.setEnergyKcal(130.0);
        rSi.setProtein(2.6);
        rSi.setTotalFat(0.3);
        rSi.setTotalCarbohydrate(28.0);
        rSi.setSodium(1.0);
        rSi.setIsDeleted(false);
        rSi.setGmtCreate(LocalDateTime.now().format(FMT));
        servingRepo.save(rSi);

        // 2. 鸡腿
        Food chicken = new Food();
        chicken.setBrand("系统");
        chicken.setProduct("煮鸡腿");
        chicken.setCategory("肉类");
        chicken.setContributor("system");
        chicken.setIsDeleted(false);
        chicken.setGmtCreate(LocalDateTime.now().format(FMT));
        chicken = foodRepo.save(chicken);

        ServingInfo cSi = new ServingInfo();
        cSi.setFoodId(chicken.getFoodId());
        cSi.setServingSize(100);
        cSi.setServingUnit("克");
        cSi.setEnergy(878.0);
        cSi.setEnergyKcal(210.0);
        cSi.setProtein(18.0);
        cSi.setTotalFat(14.0);
        cSi.setTotalCarbohydrate(0.0);
        cSi.setSodium(60.0);
        cSi.setIsDeleted(false);
        cSi.setGmtCreate(LocalDateTime.now().format(FMT));
        servingRepo.save(cSi);
    }

    private void initExercises() {
        log.info("初始化内置动作库...");
        
        String now = LocalDateTime.now().format(FMT);
        
        Exercise pushup = new Exercise();
        pushup.setExerciseCode("EXE_PUSH_UP");
        pushup.setExerciseName("俯卧撑");
        pushup.setCategory("胸部");
        pushup.setInstructions("双手撑地，与肩同宽...");
        pushup.setCountingMode("reps");
        pushup.setIsCustom(false);
        pushup.setGmtCreate(now);
        exerciseRepo.save(pushup);

        Exercise squat = new Exercise();
        squat.setExerciseCode("EXE_SQUAT");
        squat.setExerciseName("杠铃深蹲");
        squat.setCategory("腿部");
        squat.setInstructions("背负杠铃，下蹲至大腿与地面平行...");
        squat.setCountingMode("reps");
        squat.setIsCustom(false);
        squat.setGmtCreate(now);
        exerciseRepo.save(squat);

        Exercise plank = new Exercise();
        plank.setExerciseCode("EXE_PLANK");
        plank.setExerciseName("平板支撑");
        plank.setCategory("核心");
        plank.setInstructions("前臂撑地，身体呈直线...");
        plank.setCountingMode("timed");
        plank.setIsCustom(false);
        plank.setGmtCreate(now);
        exerciseRepo.save(plank);
    }
}
