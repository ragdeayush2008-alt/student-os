# Phase 10B — XP Economy Analysis

**Date:** 2026-08-29  
**Purpose:** Validate reward pricing against realistic student earning scenarios

---

## Current XP Engine Rules (from `xp_engine.dart`)

### Task Completion
- **Base XP:** 10
- **High Priority Bonus:** +10 (total: 20)
- **Critical Priority Bonus:** +20 (total: 30)

### Study Sessions
- **Minimum Duration:** 5 minutes (300 seconds)
- **Base XP:** 15
- **Per 30-min Block:** +5 XP
- **Maximum XP:** 50 (caps at ~3 hours)

Examples:
- 5 min → 15 XP
- 30 min → 20 XP
- 1 hour → 25 XP
- 1.5 hours → 30 XP
- 2 hours → 35 XP
- 3+ hours → 50 XP (capped)

### Syllabus Topics
- **Fixed XP:** 25 per topic

### Exams
- **Fixed XP:** 50 per exam

### Milestones
- **Weekly Consistency:** 30 XP
- **3-day Streak:** 20 XP
- **7-day Streak:** 40 XP
- **14-day Streak:** 60 XP
- **30-day Streak:** 100 XP

---

## Realistic Student Earning Scenarios

### Light Day (Minimal Activity)
- Complete 2 normal tasks: 2 × 10 = **20 XP**
- 30-minute study session: **20 XP**
- **Daily Total: ~40 XP**

### Normal Day (Typical Student)
- Complete 3 tasks (2 normal, 1 high priority): (2×10) + 20 = **40 XP**
- 1-hour study session: **25 XP**
- Complete 1 syllabus topic: **25 XP**
- **Daily Total: ~90 XP**

### Heavy Study Day (Exam Prep)
- Complete 5 tasks (2 normal, 2 high, 1 critical): 20 + 40 + 30 = **90 XP**
- 2-hour study session: **35 XP**
- Complete 3 syllabus topics: 3 × 25 = **75 XP**
- **Daily Total: ~200 XP**

### Exam Week
- Heavy study day × 5 days: 5 × 200 = **1,000 XP**
- Complete exam: **50 XP**
- 7-day streak bonus: **40 XP**
- **Weekly Total: ~1,090 XP**

### Highly Consistent Week (No Exam)
- Normal day × 7 days: 7 × 90 = **630 XP**
- Weekly consistency bonus: **30 XP**
- 7-day streak bonus: **40 XP**
- **Weekly Total: ~700 XP**

### Monthly Consistency (Regular Student)
- 4 consistent weeks: 4 × 700 = **2,800 XP**
- 14-day streak bonus: **60 XP**
- 30-day streak bonus: **100 XP**
- **Monthly Total: ~2,960 XP**

### New Student (First Week)
- Light/normal days as they learn the app: 5 × 50 = **250 XP**
- No streak bonuses yet
- **Weekly Total: ~250 XP**

---

## Current Reward Catalog Pricing (from `reward_catalog.dart`)

| Reward | Type | XP Cost | Min Level | Category |
|--------|------|---------|-----------|----------|
| First Steps | Badge | 50 | 1 | Featured |
| Focus Theme | Theme | 150 | 3 | Featured |
| Consistent Learner | Badge | 200 | 5 | Cosmetic |
| Academic Light | Theme | 250 | 5 | Cosmetic |
| Midnight Scholar | Theme | 350 | 8 | Cosmetic |
| Exam Master | Badge | 400 | 10 | Cosmetic |
| Advanced Analytics | Feature | 500 | 10 | Academic (Coming Soon) |
| Smart Scheduling | Feature | 600 | 12 | Academic (Coming Soon) |
| Premium Trial | Discount | 800 | 15 | Premium (Coming Soon) |
| Premium Discount | Discount | 1000 | 20 | Premium (Coming Soon) |
| Student OS Legend | Badge | 5000 | 50 | Feature |

---

## Economic Balance Analysis

### Early Rewards (50-250 XP)
**Affordable Timeline:**
- **First Steps (50 XP):** 1-2 days of light use ✅ GOOD
- **Focus Theme (150 XP):** ~2-3 normal days ✅ GOOD
- **Consistent Learner (200 XP):** ~3 days ✅ GOOD
- **Academic Light (250 XP):** ~3-4 days ✅ GOOD

**Assessment:** Well-balanced for new students. First reward achievable quickly, subsequent rewards require sustained engagement.

### Mid-Tier Rewards (350-600 XP)
**Affordable Timeline:**
- **Midnight Scholar (350 XP):** ~4-5 days ✅ GOOD
- **Exam Master (400 XP):** ~5 days or 2 exam-prep days ✅ GOOD
- **Advanced Analytics (500 XP):** ~6 days or 1 exam week ✅ GOOD
- **Smart Scheduling (600 XP):** ~7 days ✅ GOOD

**Assessment:** Require meaningful commitment. Students earning these have demonstrated consistent use.

### Premium Rewards (800-1000 XP)
**Affordable Timeline:**
- **Premium Trial (800 XP):** ~9-12 days or ~1 week of exam prep ✅ GOOD
- **Premium Discount (1000 XP):** ~11-14 days or 1.5 exam weeks ✅ GOOD

**Assessment:** Substantial commitment required. Appropriate for premium benefits.

### Elite Reward (5000 XP)
**Affordable Timeline:**
- **Student OS Legend (5000 XP):** ~2 months of consistent use or ~5 exam cycles 🟡 VERY HIGH

**Assessment:** Extremely rare achievement. May be too high unless intended as long-term aspirational goal.

---

## Level Progression Context

From Phase 9, Level progression requires:
- Level 1: 0 XP
- Level 3: ~90 XP (2-3 days)
- Level 5: ~180 XP (~1 week light use)
- Level 8: ~350 XP (~1-2 weeks)
- Level 10: ~500 XP (~2 weeks)
- Level 15: ~1,200 XP (~3-4 weeks)
- Level 20: ~2,200 XP (~2 months)
- Level 50: ~15,000 XP (~6+ months)

Level requirements are gating some rewards appropriately.

---

## Issues Identified

### 1. ✅ Early Progression: BALANCED
First Steps → Focus Theme → Consistent Learner progression is well-paced.

### 2. ✅ Mid-Tier: BALANCED
350-600 XP rewards require 1-2 weeks of engagement, appropriate for cosmetic/feature unlocks.

### 3. 🟡 Premium Pricing: SLIGHTLY HIGH
- 800-1000 XP may feel steep for trials/discounts
- Consider: Are these prices appropriate for the value delivered?
- Recommendation: Keep current pricing but ensure Premium trials deliver real value

### 4. 🔴 Legend Badge: TOO HIGH
5000 XP requires 2+ months of consistent daily use. This may be:
- Too far in the future for most students
- Demotivating rather than aspirational
- Recommendation: Consider reducing to 3000-3500 XP (~6-8 weeks)

### 5. ✅ Coming Soon Items: APPROPRIATE
Advanced Analytics, Smart Scheduling, Premium features are marked "Coming Soon" correctly.

### 6. 🟢 No Economy Breaking Issues
- No rewards are trivially cheap
- No extreme inflation risk
- Progression feels earnable but requires effort

---

## Recommendations

### Immediate Actions
1. **Keep current pricing** for rewards 50-1000 XP ✅
2. **Reduce Legend Badge** from 5000 → 3500 XP 🔧
3. **Monitor** student feedback on Premium pricing once trials are functional

### Future Considerations
1. Add mid-range rewards around 1500-2500 XP for 4-6 week milestones
2. Consider seasonal/event rewards with limited-time pricing
3. Add subject-specific rewards tied to academic milestones

---

## Conclusion

**Overall Economy: BALANCED ✅**

The reward economy is well-designed with appropriate progression gates. Early rewards encourage adoption, mid-tier rewards reward consistency, and premium rewards require substantial commitment. Only the Legend badge pricing needs adjustment.

The economy supports the core loop:
STUDY → PROGRESS → XP → REWARDS → BETTER EXPERIENCE

No fundamental changes needed beyond minor price adjustment.
