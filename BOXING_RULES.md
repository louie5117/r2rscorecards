# Boxing Scoring Rules Implementation

## Queensberry Rules - 10-Point Must System

This app implements proper boxing scoring according to the **10-Point Must System** used in professional boxing.

### Basic Rules

1. **The winner of a round must receive 10 points** (or less if point deductions apply)
2. **The loser receives 9 or fewer points**
3. **Even rounds are scored 10-10** (both fighters performed equally)
4. **Point deductions reduce the offending fighter's score**

### Valid Score Combinations

#### Most Common Scores
- **10-9**: Clear winner of the round (most common)
- **10-10**: Completely even round (rare but valid)
- **10-8**: Dominant round or one knockdown
- **10-7**: Multiple knockdowns or extremely dominant
- **10-6**: Extremely rare, multiple knockdowns

#### Scores with Point Deductions
- **9-9**: Even round with 1-point deduction to both fighters
- **9-8**: Winner gets 9 (due to deduction), loser gets 8
- **8-7**: Both fighters have deductions, but one won the round

### Invalid Combinations

These scores are **NOT allowed** under standard boxing rules:
- ❌ **8-8**: Not valid (closest would be 9-9 with deductions)
- ❌ **7-7**: Not valid
- ❌ **11-10**: No fighter can receive more than 10 points
- ❌ **10-5**: Difference of 5+ points is not allowed

### Point Deductions

Referees can deduct points for fouls such as:
- Low blows
- Holding
- Headbutts
- Hitting after the bell
- Other infractions

**Deductions:**
- Usually 1 point for minor fouls
- 2 points for serious fouls
- Multiple deductions can occur

**Example:** If Red wins the round but has a point deducted:
- Red: 10 (won round) - 1 (deduction) = **9 points**
- Blue: 9 (lost round) = **9 points**
- Final score: **9-9**

### How Knockdowns Affect Scoring

- **One knockdown**: Winner gets 10, loser gets 8 (10-8)
- **Two knockdowns**: Winner gets 10, loser gets 7 (10-7)
- **Three knockdowns**: Usually results in a stoppage

### App Implementation

The app enforces these rules by:

1. **Validation**: The `BoxingRules` helper validates all score combinations
2. **UI Guidance**: Quick-select buttons for common scores (10-9, 10-10, etc.)
3. **Advanced Options**: Access to knockdown scores and deductions
4. **Error Prevention**: Invalid scores are flagged before submission
5. **Score Descriptions**: Shows what each score means (e.g., "Red wins clearly")

### Scoring Interface

When scoring a round, you'll see:

1. **Quick Selection Buttons:**
   - Red Wins (10-9)
   - Blue Wins (9-10)
   - Even Round (10-10)
   - More Options (knockdowns, deductions)

2. **Current Score Display:** Shows the current scores for both fighters

3. **Score Description:** Explains what the current score means

4. **Advanced Options:** Expandable section for:
   - Dominant rounds (10-8)
   - Knockdown scenarios (10-7)
   - Point deductions (9-9, 9-8)
   - Manual adjustment (if needed)

### Resources

For more information on boxing scoring:
- [World Boxing Association Rules](https://www.wbaboxing.com/)
- [International Boxing Federation Rules](https://www.ibf-usba-boxing.com/)
- [10-Point Must System Explained](https://en.wikipedia.org/wiki/10-point_must_system)
