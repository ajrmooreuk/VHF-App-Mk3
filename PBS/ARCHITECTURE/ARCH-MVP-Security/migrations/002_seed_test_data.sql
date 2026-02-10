-- ============================================================
-- VHF TEST DATA SEED
-- Supabase Migration: 002_seed_test_data
-- Date: 2026-02-10
--
-- Loads test personas, recipes, and themes from ontology
-- into JSONB-backed MVP schema with RLS-compatible tenant_id
-- ============================================================

-- Create test tenant
INSERT INTO tenants (id, name, slug, settings) VALUES (
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Viridian Health & Fitness',
    'viridian-hf',
    '{"location": "Kings Worthy, Winchester, Hampshire", "country": "GB"}'
) ON CONFLICT (slug) DO NOTHING;

-- Set context for seed operations
SELECT set_tenant_context(
    '11111111-1111-1111-1111-111111111111'::UUID,
    '00000000-0000-0000-0000-000000000099'::UUID,
    'super_admin'
);

-- ============================================================
-- COACH
-- ============================================================
INSERT INTO coaches (id, tenant_id, name, email, profile, qualifications, specialisms) VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'James Kerby',
    'james@viridian-hf.com',
    '{
        "@context": "https://schema.org",
        "@type": "Person",
        "givenName": "James",
        "familyName": "Kerby",
        "jobTitle": "Personal Trainer Coach & Clinical Weight-Loss Practitioner",
        "worksFor": {
            "@type": "Organization",
            "name": "Viridian Health & Fitness"
        }
    }'::JSONB,
    ARRAY['Level 5 Clinical Weight Loss Practitioner', 'Diploma in Sports Science', 'Nutrition and Weight Management Qualified'],
    ARRAY['weight-loss', 'strength-training', 'injury-rehabilitation', 'seniors', 'sports-performance']
) ON CONFLICT DO NOTHING;

-- ============================================================
-- CLIENTS (12 test personas)
-- ============================================================

-- TP-001: Sarah Mitchell (GOOD — Diabetic, Low Carb, Nut-Free)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0001-0001-0001-000000000001'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Sarah Mitchell', 'sarah.mitchell@test.vhf', '1985-03-15', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Sarah", "familyName": "Mitchell", "gender": "Female",
        "height": {"@type": "QuantitativeValue", "value": 168, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 82, "unitCode": "KGM"},
        "medicalCondition": [{"@type": "MedicalCondition", "name": "Type 2 Diabetes", "code": {"@type": "MedicalCode", "code": "E11", "codingSystem": "ICD-10"}, "status": "managed"}],
        "_custom": {
            "bmi": 29.1, "activityLevel": "moderately_active",
            "goal": "weight_loss",
            "dietTypes": ["diabetic", "low-carb"],
            "dietaryRestrictions": ["low-glycemic", "controlled-carbs"],
            "allergens": ["tree-nuts", "peanuts"],
            "macroTargets": {"dailyCalories": 1650, "proteinGrams": 120, "carbsGrams": 140, "fatsGrams": 55},
            "preferredThemes": ["QuickWeeknight", "HighProtein", "DiabeticFriendly"]
        }
    }'::JSONB
);

-- TP-002: Raj Patel (GOOD — Hindu Vegetarian, High Protein)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0002-0002-0002-000000000002'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Raj Patel', 'raj.patel@test.vhf', '1990-07-22', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Raj", "familyName": "Patel", "gender": "Male",
        "height": {"@type": "QuantitativeValue", "value": 178, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 72, "unitCode": "KGM"},
        "medicalCondition": [],
        "_custom": {
            "bmi": 22.7, "activityLevel": "very_active",
            "goal": "muscle_gain",
            "dietTypes": ["hindu-vegetarian", "high-protein"],
            "dietaryRestrictions": ["lacto-vegetarian", "no-eggs"],
            "allergens": [],
            "macroTargets": {"dailyCalories": 2800, "proteinGrams": 168, "carbsGrams": 350, "fatsGrams": 78},
            "preferredThemes": ["HighProtein", "AsianFusion", "BatchCookSunday"]
        }
    }'::JSONB
);

-- TP-003: Fatima Al-Rashid (GOOD — Halal, Anti-Inflammatory, PCOS)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0003-0003-0003-000000000003'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Fatima Al-Rashid', 'fatima.alrashid@test.vhf', '1988-11-03', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Fatima", "familyName": "Al-Rashid", "gender": "Female",
        "height": {"@type": "QuantitativeValue", "value": 162, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 78, "unitCode": "KGM"},
        "medicalCondition": [{"@type": "MedicalCondition", "name": "Polycystic Ovary Syndrome (PCOS)", "code": {"@type": "MedicalCode", "code": "E28.2", "codingSystem": "ICD-10"}, "status": "active"}],
        "_custom": {
            "bmi": 29.7, "activityLevel": "lightly_active",
            "goal": "weight_loss",
            "dietTypes": ["halal", "anti-inflammatory"],
            "dietaryRestrictions": ["halal-certified-meat", "no-pork", "no-alcohol", "low-refined-sugar"],
            "allergens": ["sesame"],
            "macroTargets": {"dailyCalories": 1500, "proteinGrams": 112, "carbsGrams": 120, "fatsGrams": 58},
            "preferredThemes": ["PCOSSupport", "Mediterranean", "BudgetFriendly"]
        }
    }'::JSONB
);

-- TP-004: Tom Jeffries (GOOD — Mediterranean, Low Sodium, Senior)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0004-0004-0004-000000000004'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Tom Jeffries', 'tom.jeffries@test.vhf', '1972-01-19', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Tom", "familyName": "Jeffries", "gender": "Male",
        "height": {"@type": "QuantitativeValue", "value": 180, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 88, "unitCode": "KGM"},
        "medicalCondition": [
            {"@type": "MedicalCondition", "name": "Osteoarthritis (knee)", "code": {"@type": "MedicalCode", "code": "M17", "codingSystem": "ICD-10"}, "status": "post-operative"},
            {"@type": "MedicalCondition", "name": "Hypertension", "code": {"@type": "MedicalCode", "code": "I10", "codingSystem": "ICD-10"}, "status": "managed"}
        ],
        "_custom": {
            "bmi": 27.2, "activityLevel": "lightly_active",
            "goal": "maintenance",
            "dietTypes": ["mediterranean", "low-sodium", "anti-inflammatory"],
            "dietaryRestrictions": ["low-sodium", "anti-inflammatory"],
            "allergens": [],
            "macroTargets": {"dailyCalories": 2100, "proteinGrams": 105, "carbsGrams": 240, "fatsGrams": 75},
            "preferredThemes": ["Mediterranean", "AntiInflammatory", "BritishComfort"]
        }
    }'::JSONB
);

-- TP-005: Emma Chen (GOOD — Vegan triathlete, Soya/Nut-Free)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0005-0005-0005-000000000005'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Emma Chen', 'emma.chen@test.vhf', '1995-06-30', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Emma", "familyName": "Chen", "gender": "Female",
        "height": {"@type": "QuantitativeValue", "value": 170, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 60, "unitCode": "KGM"},
        "medicalCondition": [],
        "_custom": {
            "bmi": 20.8, "activityLevel": "extremely_active",
            "goal": "sports_performance",
            "dietTypes": ["vegan", "high-protein"],
            "dietaryRestrictions": ["vegan", "no-animal-products"],
            "allergens": ["soya", "tree-nuts", "peanuts"],
            "macroTargets": {"dailyCalories": 2600, "proteinGrams": 130, "carbsGrams": 390, "fatsGrams": 65},
            "preferredThemes": ["HighProtein", "EnergyBoost", "AsianFusion"]
        }
    }'::JSONB
);

-- TP-006: David Goldstein (GOOD — Kosher, Low-FODMAP, IBS)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0006-0006-0006-000000000006'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'David Goldstein', 'david.goldstein@test.vhf', '1980-09-14', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "David", "familyName": "Goldstein", "gender": "Male",
        "height": {"@type": "QuantitativeValue", "value": 175, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 95, "unitCode": "KGM"},
        "medicalCondition": [{"@type": "MedicalCondition", "name": "Irritable Bowel Syndrome (IBS-D)", "code": {"@type": "MedicalCode", "code": "K58.0", "codingSystem": "ICD-10"}, "status": "active"}],
        "_custom": {
            "bmi": 31.0, "activityLevel": "sedentary",
            "goal": "weight_loss",
            "dietTypes": ["kosher", "low-fodmap"],
            "dietaryRestrictions": ["kosher-certified", "no-meat-dairy-mixing", "low-fodmap"],
            "allergens": ["crustaceans", "molluscs"],
            "macroTargets": {"dailyCalories": 1800, "proteinGrams": 135, "carbsGrams": 160, "fatsGrams": 65},
            "preferredThemes": ["LowFODMAP", "HighProtein", "FamilyMeals"]
        }
    }'::JSONB
);

-- TP-007: Karen Whitfield (GOOD — Keto, Egg/Dairy-Free, Hypothyroidism)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0007-0007-0007-000000000007'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Karen Whitfield', 'karen.whitfield@test.vhf', '1968-04-07', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Karen", "familyName": "Whitfield", "gender": "Female",
        "height": {"@type": "QuantitativeValue", "value": 165, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 90, "unitCode": "KGM"},
        "medicalCondition": [{"@type": "MedicalCondition", "name": "Hypothyroidism", "code": {"@type": "MedicalCode", "code": "E03.9", "codingSystem": "ICD-10"}, "status": "managed"}],
        "_custom": {
            "bmi": 33.1, "activityLevel": "lightly_active",
            "goal": "weight_loss",
            "dietTypes": ["keto"],
            "dietaryRestrictions": ["ketogenic", "net-carbs-under-20g"],
            "allergens": ["eggs", "milk"],
            "macroTargets": {"dailyCalories": 1500, "proteinGrams": 94, "carbsGrams": 20, "fatsGrams": 117},
            "preferredThemes": ["LowCarb", "BritishComfort", "QuickWeeknight"]
        }
    }'::JSONB
);

-- TP-008: Marcus Williams (POOR DATA — validation testing)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0008-0008-0008-000000000008'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Marcus Williams', 'marcus.williams@test.vhf', '1998-12-01', 'poor',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Marcus", "familyName": "Williams", "gender": "Male",
        "height": null,
        "weight": {"@type": "QuantitativeValue", "value": 110, "unitCode": "KGM"},
        "medicalCondition": [{"@type": "MedicalCondition", "name": "asthma", "status": "active"}],
        "_custom": {
            "bmi": null, "activityLevel": "very_active",
            "goal": "weight_loss",
            "dietTypes": ["carnivore"],
            "dietaryRestrictions": ["nut-free"],
            "allergens": [],
            "macroTargets": {"dailyCalories": 800, "proteinGrams": 200, "carbsGrams": 50, "fatsGrams": 20},
            "validationErrors": [
                "height is null",
                "dailyCalories 800 below 1500 minimum for males",
                "protein 200g * 4 = 800kcal exceeds total 800kcal",
                "macros sum to 1180kcal != 800kcal target",
                "asthma has no ICD-10 code",
                "restriction nut-free but no allergen declared"
            ]
        }
    }'::JSONB
);

-- TP-009: Priya Sharma (GOOD — Jain, High Protein)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0009-0009-0009-000000000009'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Priya Sharma', 'priya.sharma@test.vhf', '1992-08-25', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Priya", "familyName": "Sharma", "gender": "Female",
        "height": {"@type": "QuantitativeValue", "value": 158, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 52, "unitCode": "KGM"},
        "medicalCondition": [],
        "_custom": {
            "bmi": 20.8, "activityLevel": "moderately_active",
            "goal": "muscle_gain",
            "dietTypes": ["jain", "high-protein"],
            "dietaryRestrictions": ["jain-strict", "no-root-vegetables", "no-eggs", "no-honey", "no-alcohol"],
            "allergens": [],
            "macroTargets": {"dailyCalories": 2000, "proteinGrams": 104, "carbsGrams": 260, "fatsGrams": 56},
            "preferredThemes": ["HighProtein", "AsianFusion", "BudgetFriendly"]
        }
    }'::JSONB
);

-- TP-010: Jake Thompson (POOR DATA — conflicting diets)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0010-0010-0010-000000000010'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Jake Thompson', 'jake.thompson@test.vhf', '2001-03-10', 'poor',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Jake", "familyName": "Thompson", "gender": "Male",
        "height": {"@type": "QuantitativeValue", "value": 185, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 78, "unitCode": "KGM"},
        "medicalCondition": [],
        "_custom": {
            "bmi": 22.8, "activityLevel": "moderately_active",
            "goal": "maintenance",
            "dietTypes": ["vegan", "carnivore", "keto"],
            "dietaryRestrictions": ["vegan", "carnivore", "keto"],
            "allergens": ["milk"],
            "macroTargets": {"dailyCalories": 2500, "proteinGrams": 150, "carbsGrams": 250, "fatsGrams": 83},
            "validationErrors": [
                "vegan and carnivore are mutually exclusive",
                "milk allergen conflicts with keto (dairy-dependent)",
                "three incompatible diet types declared"
            ]
        }
    }'::JSONB
);

-- TP-011: Linda Okafor (GOOD — Gluten-Free, Renal, Pescatarian)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0011-0011-0011-000000000011'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Linda Okafor', 'linda.okafor@test.vhf', '1975-02-28', 'good',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Linda", "familyName": "Okafor", "gender": "Female",
        "height": {"@type": "QuantitativeValue", "value": 172, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 68, "unitCode": "KGM"},
        "medicalCondition": [
            {"@type": "MedicalCondition", "name": "Coeliac Disease", "code": {"@type": "MedicalCode", "code": "K90.0", "codingSystem": "ICD-10"}, "status": "active"},
            {"@type": "MedicalCondition", "name": "Chronic Kidney Disease Stage 2", "code": {"@type": "MedicalCode", "code": "N18.2", "codingSystem": "ICD-10"}, "status": "active"}
        ],
        "_custom": {
            "bmi": 23.0, "activityLevel": "lightly_active",
            "goal": "medical_management",
            "dietTypes": ["gluten-free", "renal", "pescatarian"],
            "dietaryRestrictions": ["gluten-free", "low-sodium", "low-potassium", "low-phosphorus", "pescatarian"],
            "allergens": ["cereals-containing-gluten"],
            "macroTargets": {"dailyCalories": 1800, "proteinGrams": 72, "carbsGrams": 230, "fatsGrams": 65},
            "preferredThemes": ["Mediterranean", "GutHealth", "SpringFresh"]
        }
    }'::JSONB
);

-- TP-012: Ben Fraser (POOR DATA — incomplete profile)
INSERT INTO clients (id, tenant_id, coach_id, name, email, date_of_birth, data_quality, profile) VALUES (
    'cccccccc-0012-0012-0012-000000000012'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
    'Ben Fraser', 'ben.fraser@test.vhf', '1993-10-17', 'poor',
    '{
        "@context": "https://schema.org",
        "@type": "Patient",
        "givenName": "Ben", "familyName": "Fraser", "gender": "Male",
        "height": {"@type": "QuantitativeValue", "value": 182, "unitCode": "CMT"},
        "weight": {"@type": "QuantitativeValue", "value": 13, "unitCode": "STN"},
        "medicalCondition": null,
        "_custom": {
            "bmi": null, "activityLevel": null,
            "goal": null,
            "dietTypes": [],
            "dietaryRestrictions": ["i dont eat much meat"],
            "allergens": [],
            "macroTargets": null,
            "validationErrors": [
                "weight unit is STN not KGM (13 stone = 82.55 kg)",
                "no goal selected",
                "no macro targets",
                "free-text dietary restriction",
                "null activity level",
                "null medical condition (should be empty array)"
            ]
        }
    }'::JSONB
);

-- ============================================================
-- SAMPLE RECIPES (first 5 to demonstrate pattern)
-- Full 30 recipes follow same pattern
-- ============================================================

INSERT INTO recipes (id, tenant_id, name, meal_type, cuisine, difficulty, total_time_minutes, uk_available, seasonal, cost_per_serving_pence, recipe_schema, nutrition, ingredients, instructions, suitable_for_diet, excludes_allergen, belongs_to_theme) VALUES
(
    'rrrrrrrr-0001-0001-0001-000000000001'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Grilled Chicken Breast with Roasted Mediterranean Vegetables',
    'dinner', 'British', 'easy', 40, true, false, 280,
    '{"@context":"https://schema.org","@type":"Recipe","name":"Grilled Chicken Breast with Roasted Mediterranean Vegetables","prepTime":"PT15M","cookTime":"PT25M","totalTime":"PT40M","recipeYield":"2 servings","recipeIngredient":["2 chicken breasts (300g)","1 courgette","1 red pepper","1 red onion","2 tbsp olive oil","1 tsp mixed herbs","salt and pepper"]}'::JSONB,
    '{"@type":"NutritionInformation","servingSize":"1 serving","calories":"380 kcal","proteinContent":"42g","carbohydrateContent":"12g","fatContent":"18g","fiberContent":"4g","sodiumContent":"180mg"}'::JSONB,
    '["2 chicken breasts (300g)","1 courgette","1 red pepper","1 red onion","2 tbsp olive oil","1 tsp mixed herbs"]'::JSONB,
    '[]'::JSONB,
    '["halal*","kosher*","high-protein","low-carb","mediterranean","paleo","gluten-free","dairy-free","low-fodmap*"]'::JSONB,
    '["milk","eggs","nuts","soya","cereals"]'::JSONB,
    '["HighProtein","Mediterranean","QuickWeeknight"]'::JSONB
),
(
    'rrrrrrrr-0002-0002-0002-000000000002'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Paneer Tikka with Cucumber Raita and Brown Rice',
    'dinner', 'Indian', 'easy', 35, true, false, 250,
    '{"@context":"https://schema.org","@type":"Recipe","name":"Paneer Tikka with Cucumber Raita and Brown Rice","prepTime":"PT20M","cookTime":"PT15M","totalTime":"PT35M","recipeYield":"2 servings","recipeIngredient":["225g paneer","150g Greek yoghurt","1 tsp turmeric","1 tsp garam masala","200g brown rice"]}'::JSONB,
    '{"@type":"NutritionInformation","servingSize":"1 serving","calories":"520 kcal","proteinContent":"32g","carbohydrateContent":"48g","fatContent":"22g","fiberContent":"4g","sodiumContent":"220mg"}'::JSONB,
    '["225g paneer","150g Greek yoghurt","1 tsp turmeric","1 tsp garam masala","200g brown rice","fresh mint"]'::JSONB,
    '[]'::JSONB,
    '["vegetarian","hindu-vegetarian","high-protein","halal"]'::JSONB,
    '["nuts","eggs","soya","fish"]'::JSONB,
    '["HighProtein","AsianFusion","BudgetFriendly"]'::JSONB
),
(
    'rrrrrrrr-0003-0003-0003-000000000003'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Salmon and Sweet Potato Tray Bake',
    'dinner', 'British', 'easy', 40, true, false, 350,
    '{"@context":"https://schema.org","@type":"Recipe","name":"Salmon and Sweet Potato Tray Bake","prepTime":"PT10M","cookTime":"PT30M","totalTime":"PT40M","recipeYield":"2 servings","recipeIngredient":["2 salmon fillets (250g)","2 medium sweet potatoes","1 broccoli head","1 tbsp olive oil","1 lemon"]}'::JSONB,
    '{"@type":"NutritionInformation","servingSize":"1 serving","calories":"450 kcal","proteinContent":"35g","carbohydrateContent":"38g","fatContent":"18g","fiberContent":"7g","sodiumContent":"120mg"}'::JSONB,
    '["2 salmon fillets (250g)","2 medium sweet potatoes","1 broccoli head","1 tbsp olive oil","1 lemon","2 garlic cloves","fresh dill"]'::JSONB,
    '[]'::JSONB,
    '["pescatarian","anti-inflammatory","mediterranean","gluten-free","dairy-free","high-protein"]'::JSONB,
    '["milk","eggs","nuts","soya","cereals"]'::JSONB,
    '["AntiInflammatory","HighProtein","QuickWeeknight","WinterWarmer"]'::JSONB
),
(
    'rrrrrrrr-0005-0005-0005-000000000005'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Chickpea and Spinach Coconut Curry (Vegan)',
    'dinner', 'Indian', 'easy', 35, true, false, 120,
    '{"@context":"https://schema.org","@type":"Recipe","name":"Chickpea and Spinach Coconut Curry","prepTime":"PT10M","cookTime":"PT25M","totalTime":"PT35M","recipeYield":"4 servings","recipeIngredient":["2 tins chickpeas","400ml coconut milk","200g spinach","1 tin tomatoes","2 tsp curry powder"]}'::JSONB,
    '{"@type":"NutritionInformation","servingSize":"1 serving with rice","calories":"380 kcal","proteinContent":"16g","carbohydrateContent":"48g","fatContent":"14g","fiberContent":"10g","sodiumContent":"150mg"}'::JSONB,
    '["2 tins chickpeas (800g)","400ml coconut milk","200g spinach","1 tin chopped tomatoes","2 tsp curry powder","1 tsp turmeric","1 onion","3 garlic cloves","rice"]'::JSONB,
    '[]'::JSONB,
    '["vegan","vegetarian","hindu-vegetarian","halal","kosher","gluten-free","dairy-free","anti-inflammatory","mediterranean"]'::JSONB,
    '["milk","eggs","nuts","peanuts","soya","cereals","fish","crustaceans"]'::JSONB,
    '["BudgetFriendly","BatchCookSunday","AsianFusion","AntiInflammatory"]'::JSONB
),
(
    'rrrrrrrr-0015-0015-0015-000000000015'::UUID,
    '11111111-1111-1111-1111-111111111111'::UUID,
    'Jain Dal Tadka with Jeera Rice (No Onion/Garlic)',
    'dinner', 'Indian', 'easy', 35, true, false, 90,
    '{"@context":"https://schema.org","@type":"Recipe","name":"Jain Dal Tadka with Jeera Rice","prepTime":"PT10M","cookTime":"PT25M","totalTime":"PT35M","recipeYield":"2 servings","recipeIngredient":["200g yellow moong dal","1 tomato","1 green chilli","asafoetida","cumin seeds","200g basmati rice","1 tbsp ghee"]}'::JSONB,
    '{"@type":"NutritionInformation","servingSize":"1 serving with rice","calories":"440 kcal","proteinContent":"20g","carbohydrateContent":"68g","fatContent":"8g","fiberContent":"10g","sodiumContent":"45mg"}'::JSONB,
    '["200g yellow moong dal","1 tomato","1 green chilli","1/4 tsp asafoetida","1 tsp cumin seeds","1 tsp turmeric","200g basmati rice","1 tbsp ghee","fresh coriander"]'::JSONB,
    '[]'::JSONB,
    '["jain","hindu-vegetarian","vegetarian","halal","gluten-free"]'::JSONB,
    '["nuts","peanuts","eggs","soya","fish","cereals","crustaceans"]'::JSONB,
    '["AsianFusion","BudgetFriendly"]'::JSONB
);

-- NOTE: Remaining 25 recipes follow identical INSERT pattern.
-- In production, load from test-recipes.jsonld via application seed script.

-- ============================================================
-- VERIFICATION: Run after seeding
-- ============================================================

-- Count seeded data
-- SELECT 'tenants' as entity, COUNT(*) FROM tenants
-- UNION ALL SELECT 'coaches', COUNT(*) FROM coaches
-- UNION ALL SELECT 'clients', COUNT(*) FROM clients
-- UNION ALL SELECT 'recipes', COUNT(*) FROM recipes;

-- Verify client isolation (as client TP-001)
-- SELECT set_tenant_context('11111111-1111-1111-1111-111111111111', <sarah_user_id>, 'client');
-- SELECT name FROM clients; -- Should return only 'Sarah Mitchell'
