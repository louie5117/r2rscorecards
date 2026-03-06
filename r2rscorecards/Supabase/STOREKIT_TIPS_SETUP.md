# In-App Purchase Setup: Tips & Donations

## 🎯 What's Been Added

A complete **"Support the Developer"** system using StoreKit 2 that allows users to optionally tip/donate to support your app!

### Features:
- ✅ 4 tip levels ($0.99, $2.99, $4.99, $9.99)
- ✅ Beautiful, engaging UI
- ✅ Secure Apple payment processing
- ✅ No subscriptions - just one-time tips
- ✅ Works with Apple Pay, credit cards
- ✅ Automatic receipt verification
- ✅ Ready for TestFlight and production

## 📁 Files Created

1. **`Products.storekit`** - Local StoreKit configuration for testing
2. **`StoreKitManager.swift`** - Purchase logic and transaction handling
3. **`SupportDeveloperView.swift`** - Beautiful UI for donations
4. **`SettingsView.swift`** - UPDATED with Support link

## 🚀 Setup Instructions

### Part 1: Configure in Xcode (5 minutes)

#### Step 1: Add StoreKit Configuration File

The `Products.storekit` file is already created. Now you need to tell Xcode to use it:

1. **Select your project** in the Project Navigator (blue icon)
2. **Select your app target**
3. **Go to "Signing & Capabilities" tab**
4. **Scroll down to "StoreKit Configuration"** section
5. **Click the dropdown** and select `Products.storekit`

If you don't see "StoreKit Configuration":
1. Click **"+ Capability"**
2. Search for **"In-App Purchase"**
3. Add it
4. Then you'll see the StoreKit Configuration option

#### Step 2: Update Product IDs

In `Products.storekit` and `StoreKitManager.swift`, the product IDs use:
```
com.r2rscorecards.tip.small
com.r2rscorecards.tip.medium
com.r2rscorecards.tip.large
com.r2rscorecards.tip.generous
```

**Change these to match your actual bundle identifier:**
```
com.YOURCOMPANY.YOURAPP.tip.small
com.YOURCOMPANY.YOURAPP.tip.medium
com.YOURCOMPANY.YOURAPP.tip.large
com.YOURCOMPANY.YOURAPP.tip.generous
```

Update in BOTH files!

### Part 2: Test Locally (2 minutes)

You can test immediately in the simulator or on a device!

1. **Run your app** (Cmd+R)
2. **Go to Settings** → "Support the Developer"
3. **See the tip options** loaded from `Products.storekit`
4. **Tap a tip option** to test the purchase flow
5. **Xcode will show a test purchase dialog**
6. **Confirm** to complete the test purchase

✅ This works immediately without any App Store setup!

### Part 3: App Store Connect Setup (Before Release)

Before you can release the app and accept real money, you need to set up products in App Store Connect:

#### Step 1: Sign Agreements

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"Agreements, Tax, and Banking"**
3. Accept the **"Paid Applications" agreement**
4. Complete **tax information**
5. Add **banking information** (where you'll receive payments)

⚠️ **You must complete this before you can create IAP products!**

#### Step 2: Create In-App Purchases

1. Go to your app in App Store Connect
2. Click **"In-App Purchases"**
3. Click **"+"** to create a new product
4. Select **"Consumable"**

Create each tip product:

**Small Tip:**
- **Product ID:** `com.r2rscorecards.tip.small` (match exactly!)
- **Reference Name:** "Small Tip"
- **Price:** Tier 1 ($0.99)
- **Display Name:** "Small Tip"
- **Description:** "Buy me a coffee! Support the development of R2R Scorecards."

**Medium Tip:**
- **Product ID:** `com.r2rscorecards.tip.medium`
- **Reference Name:** "Medium Tip"
- **Price:** Tier 3 ($2.99)
- **Display Name:** "Medium Tip"
- **Description:** "Buy me lunch! Your support helps keep the app running."

**Large Tip:**
- **Product ID:** `com.r2rscorecards.tip.large`
- **Reference Name:** "Large Tip"
- **Price:** Tier 5 ($4.99)
- **Display Name:** "Large Tip"
- **Description:** "You're amazing! This helps me dedicate more time to improving the app."

**Generous Tip:**
- **Product ID:** `com.r2rscorecards.tip.generous`
- **Reference Name:** "Generous Tip"
- **Price:** Tier 10 ($9.99)
- **Display Name:** "Generous Tip"
- **Description:** "Wow! Your generosity is incredible. Thank you for believing in this app!"

#### Step 3: Submit for Review

Each product needs to be reviewed by Apple. This happens automatically when you submit your app for review.

**For review, you'll need:**
- ✅ Screenshot of the tip screen (already created!)
- ✅ Clear description that it's a voluntary tip

### Part 4: TestFlight Testing

Before releasing to the public, test with real Apple IDs in TestFlight:

1. **Create a TestFlight build**
2. **Add internal/external testers**
3. **Testers can make real purchases** (but won't be charged)
4. **Test the full purchase flow**

#### Sandbox Testing:

You can also use Sandbox test accounts:

1. **Go to App Store Connect** → Users and Access → Sandbox Testers
2. **Create test accounts** with fake emails
3. **Sign in with these accounts** in Settings → App Store on your device
4. **Make test purchases** (won't charge real money)

## 💰 How Payments Work

### Apple's Cut:
- Apple takes **15%** for small developers (less than $1M/year)
- Apple takes **30%** for larger developers
- You receive **70-85%** of each tip

### Payout Schedule:
- Apple pays **monthly**
- Requires **minimum threshold** (usually $150)
- Direct deposit to your bank account

### Supported Payment Methods:
✅ **Apple Pay** (if user has it set up)
✅ **Credit/Debit Cards** stored in App Store
✅ **App Store Credit**
✅ **Carrier Billing** (some countries)
✅ **PayPal** (in some regions)

**Note:** You don't need to integrate PayPal separately - it's handled by Apple!

## 🎨 Customization

### Change Tip Amounts:

In `Products.storekit`, change `"displayPrice"` values:
```json
{
  "displayPrice": "1.99",  // Change this
  ...
}
```

### Add More Tip Options:

1. Add to `TipProduct` enum in `StoreKitManager.swift`
2. Add to `Products.storekit`
3. Create matching product in App Store Connect

### Customize Messages:

Edit `SupportDeveloperView.swift`:
- Change header text
- Modify "What Your Support Does" section
- Update thank you message

## 📊 Track Donations (Optional)

### Add Analytics:

Uncomment the analytics line in `SupportDeveloperView.swift`:
```swift
// Analytics.logEvent("tip_purchased", parameters: ["amount": product.displayPrice])
```

Then integrate with:
- Firebase Analytics
- Apple Analytics
- Your own tracking system

### Database Tracking:

You can track tips in Supabase:
```swift
// After successful purchase:
try await supabase
    .from("user_tips")
    .insert([
        "user_id": userId.uuidString,
        "product_id": product.id,
        "amount": product.price,
        "currency": product.priceFormatStyle.currencyCode,
        "purchased_at": ISO8601DateFormatter().string(from: Date())
    ])
    .execute()
```

## 🔒 Security & Privacy

### Receipt Verification:
✅ **Automatic** - StoreKit 2 handles this
✅ **On-device** - No server needed
✅ **Secure** - Apple signs all transactions

### User Privacy:
✅ **No personal payment info shared** with you
✅ **Apple handles all payment processing**
✅ **No PCI compliance required**

### App Store Guidelines:
✅ **Uses approved "tip jar" pattern**
✅ **Doesn't gate features** (app remains free)
✅ **Clear about being optional**

## 🎯 User Experience

### How Users Access:
```
Settings → About Section → "Support the Developer ❤️"
```

### Purchase Flow:
1. User taps "Support the Developer"
2. Sees beautiful tip options with emojis
3. Taps a tip amount
4. Apple shows native payment confirmation
5. User authorizes with Face ID/Touch ID/Password
6. Purchase completes
7. Thank you message appears! 🎉

### After Purchase:
- ✅ Receipt automatically stored on device
- ✅ Can be restored on other devices
- ✅ Transaction appears in App Store purchase history

## ❓ Troubleshooting

### "Products not loading" in simulator:
- Make sure StoreKit configuration is selected in Scheme settings
- Scheme → Edit Scheme → Run → Options → StoreKit Configuration

### "Cannot connect to App Store" in production:
- Wait 24 hours after creating products in App Store Connect
- Products must be approved before they appear

### Testing on device shows "Cannot purchase":
- Make sure you're signed in with a Sandbox test account
- Settings → App Store → sign out of real account
- Launch app and try to purchase → sign in with sandbox account

### Payment not working:
- Check that Paid Applications agreement is signed
- Verify banking information is complete
- Make sure product IDs match exactly

## 📝 App Store Review Notes

When submitting your app:

**In the Review Notes, include:**
```
In-App Purchase Testing:

The app includes optional tips/donations to support development.
These are purely voluntary - all features remain free.

Tip products:
- Small Tip ($0.99)
- Medium Tip ($2.99)
- Large Tip ($4.99)
- Generous Tip ($9.99)

To test: Settings → Support the Developer

Sandbox test account: [provide email and password]
```

## ✅ Pre-Launch Checklist

Before releasing:

- [ ] Update product IDs to match your bundle ID
- [ ] Sign Paid Applications agreement
- [ ] Add banking information
- [ ] Create all products in App Store Connect
- [ ] Test with Sandbox accounts
- [ ] Test in TestFlight with real users
- [ ] Customize tip descriptions to your preference
- [ ] Update "Support the Developer" screen text
- [ ] Test purchase flow end-to-end
- [ ] Verify thank you messages work

## 🎉 You're All Set!

Users can now support your app development through voluntary tips!

**Remember:**
- It's completely optional
- Users get nothing blocked
- It's just a way for appreciative users to say thanks
- Every little bit helps with server costs and motivation!

---

**Created:** March 5, 2026  
**Status:** ✅ Ready to Use (after App Store Connect setup)
