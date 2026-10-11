import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/billing_service.dart';
import '../core/services/iap_config_service.dart';
import '../core/services/storage_service.dart';
import '../models/app_theme_preset.dart';
import '../models/shop_coin_event.dart';
import '../models/shop_item.dart';

enum ShopPurchaseResult {
  success,
  insufficientCoins,
  alreadyOwned,
  notFound,
  error,
}

class ShopProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _coinsKey = 'dr_coins';
  static const _ownedKey = 'dr_owned_items';
  static const _activeThemeKey = 'dr_active_theme';
  static const _activeBgKey = 'dr_active_background';
  static const _activeSkinKey = 'dr_active_skin';
  static const _lastDailyKey = 'dr_last_daily_reward';
  static const _noteRewardDateKey = 'dr_note_reward_date';
  static const _noteRewardCountKey = 'dr_note_reward_count';
  static const _processedPurchasesKey = 'dr_processed_purchases';
  static const _lastSpinKey = 'dr_last_spin_date';
  static const _loginStreakKey = 'dr_login_streak';
  static const _lastStreakDateKey = 'dr_last_streak_date';
  static const _firstPurchaseBonusKey = 'dr_first_purchase_bonus_used';

  final IapConfigService _configService = IapConfigService();
  final BillingService _billing = BillingService();
  final _random = Random();

  int _coins = 0;
  int _loginStreak = 0;
  bool _firstPurchaseBonusAvailable = true;
  Set<String> _ownedItems = {};
  String _activeThemeId = ShopCatalog.defaultThemeId;
  String _activeBackgroundId = ShopCatalog.defaultBackgroundId;
  String _activeSkinId = ShopCatalog.defaultSkinId;
  bool _isPurchasing = false;
  bool _isLoading = true;
  bool _observing = false;
  bool _attemptLive = false;
  int _purchaseAttempt = 0;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  Timer? _purchaseWatchdog;
  String? _lastMessage;
  Set<String> _processedPurchaseIds = {};
  ShopCoinEvent? _lastCoinEvent;

  int get coins => _coins;
  int get loginStreak => _loginStreak;
  bool get firstPurchaseBonusAvailable => _firstPurchaseBonusAvailable;
  int get weeklyHotDealPackIndex => IapConstants.weeklyHotDealPackIndex();
  int get weeklyHotDealPackNumber => weeklyHotDealPackIndex + 1;

  ShopItem? get nextUnlockItem {
    ShopItem? cheapest;
    for (final item in ShopCatalog.items) {
      if (_ownedItems.contains(item.id)) continue;
      if (cheapest == null || item.price < cheapest.price) cheapest = item;
    }
    return cheapest;
  }

  int get coinsToNextUnlock {
    final next = nextUnlockItem;
    if (next == null) return 0;
    return (next.price - _coins).clamp(0, next.price);
  }

  double get unlockProgress {
    final next = nextUnlockItem;
    if (next == null || next.price <= 0) return 1;
    return (_coins / next.price).clamp(0.0, 1.0);
  }

  bool get hasAffordableUnlock => nextUnlockItem != null && _coins >= nextUnlockItem!.price;
  Set<String> get ownedItems => _ownedItems;
  String get activeThemeId => _activeThemeId;
  String get activeBackgroundId => _activeBackgroundId;
  String get activeSkinId => _activeSkinId;
  bool get isPurchasing => _isPurchasing;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  ShopCoinEvent? get lastCoinEvent => _lastCoinEvent;
  IapConfigService get configService => _configService;
  BillingService get billing => _billing;

  bool get isBillingDisabled => _configService.isBillingDisabled;
  bool get isBillingAvailable =>
      !isBillingDisabled && _billing.isAvailable && _billing.products.isNotEmpty;
  IapConfigStatus get configStatus => _configService.status;

  bool get hasRemoveAds => _ownedItems.contains('remove_ads');
  bool get hasUnlimitedNotes => _ownedItems.contains('feat_unlimited_notes');
  bool get hasVoiceMemo => _ownedItems.contains('feat_voice_memo');
  bool get hasExport => _ownedItems.contains('feat_export');
  bool get hasBackup => _ownedItems.contains('feat_backup');
  bool get hasWidget => _ownedItems.contains('feat_widget');
  bool get hasUnlimitedLabels => _ownedItems.contains('feat_unlimited_labels');
  bool get hasUnlimitedPins => _ownedItems.contains('feat_pin_unlimited');

  int noteLimit(bool hasPremium) => hasPremium ? IapConstants.premiumNoteLimit : IapConstants.freeNoteLimit;
  int labelLimit(bool hasPremium) => hasPremium ? IapConstants.premiumLabelLimit : IapConstants.freeLabelLimit;
  int pinLimit(bool hasPremium) => hasPremium ? IapConstants.premiumPinLimit : IapConstants.freePinLimit;
  int voiceLimitSec(bool hasPremium) => hasPremium ? IapConstants.premiumVoiceSeconds : IapConstants.freeVoiceSeconds;

  AppThemePreset get activeTheme => AppThemePresets.get(_activeThemeId);
  AppBackground get activeBackground => AppBackground.get(_activeBackgroundId);
  CardStyle get activeCardStyle => CardStyle.get(_activeSkinId);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _ensureObserver();

    await _loadLocal();
    await _configService.fetch();

    if (!isBillingDisabled && (Platform.isAndroid || Platform.isIOS)) {
      await _billing.init(
        onPurchase: _handlePurchase,
        onError: _onBillingError,
        onCanceled: _onBillingCanceled,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshConfig() async {
    await _configService.fetch(forceRefresh: true);
    notifyListeners();
  }

  Future<void> _loadLocal() async {
    _coins = await StorageService.instance.getInt(_coinsKey) ?? 0;
    final owned = await StorageService.instance.getStringList(_ownedKey);
    _ownedItems = owned?.toSet() ?? {};
    _activeThemeId =
        await StorageService.instance.getString(_activeThemeKey) ?? ShopCatalog.defaultThemeId;
    _activeBackgroundId =
        await StorageService.instance.getString(_activeBgKey) ?? ShopCatalog.defaultBackgroundId;
    _activeSkinId =
        await StorageService.instance.getString(_activeSkinKey) ?? ShopCatalog.defaultSkinId;
    final processed = await StorageService.instance.getStringList(_processedPurchasesKey);
    _processedPurchaseIds = processed?.toSet() ?? {};
    _loginStreak = await StorageService.instance.getInt(_loginStreakKey) ?? 0;
    _firstPurchaseBonusAvailable = !(await StorageService.instance.getBool(_firstPurchaseBonusKey) ?? false);
  }

  Future<void> _saveLocal() async {
    await StorageService.instance.saveInt(_coinsKey, _coins);
    await StorageService.instance.saveStringList(_ownedKey, _ownedItems.toList());
    await StorageService.instance.saveString(_activeThemeKey, _activeThemeId);
    await StorageService.instance.saveString(_activeBgKey, _activeBackgroundId);
    await StorageService.instance.saveString(_activeSkinKey, _activeSkinId);
    await StorageService.instance.saveStringList(_processedPurchasesKey, _processedPurchaseIds.toList());
  }

  bool ownsItem(String id) => _ownedItems.contains(id);

  ShopPurchaseResult buyWithCoins(String itemId) {
    final item = ShopCatalog.find(itemId);
    if (item == null) return ShopPurchaseResult.notFound;
    if (item.oneTime && _ownedItems.contains(itemId)) {
      return ShopPurchaseResult.alreadyOwned;
    }
    if (_coins < item.price) return ShopPurchaseResult.insufficientCoins;

    _coins -= item.price;
    _ownedItems.add(itemId);
    _applyItem(item);
    _lastMessage = 'purchaseSuccess';
    _saveLocal();
    notifyListeners();
    return ShopPurchaseResult.success;
  }

  void _applyItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.theme:
        _activeThemeId = item.id;
      case ShopItemType.background:
        _activeBackgroundId = item.id;
      case ShopItemType.skin:
        _activeSkinId = item.id;
      case ShopItemType.removeAds:
      case ShopItemType.feature:
        break;
    }
  }

  Future<bool> buyCoinPack(ProductDetails product) async {
    if (isBillingDisabled || !_billing.isAvailable) return false;
    _beginPurchase();
    final ok = await _billing.buyCoinPack(product);
    if (!ok) _failPurchase();
    return ok;
  }

  Future<bool> buyRemoveAdsViaBilling() async {
    if (isBillingDisabled || !_billing.isAvailable || _billing.removeAdsProduct == null) {
      return false;
    }
    if (hasRemoveAds) return false;
    _beginPurchase();
    final ok = await _billing.buyRemoveAds();
    if (!ok) _failPurchase();
    return ok;
  }

  Future<void> restorePurchases() async {
    if (isBillingDisabled || !_billing.isAvailable) return;
    await _billing.restorePurchases();
  }

  void releasePurchaseUi() {
    if (!_isResumed) return;
    if (!_isPurchasing && !_attemptLive) return;
    _finishAttempt(failed: false);
  }

  bool get _isResumed {
    final state = WidgetsBinding.instance.lifecycleState ?? _lifecycle;
    return state == AppLifecycleState.resumed;
  }

  void _ensureObserver() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed && _isPurchasing) {
      _armWatchdog(const Duration(milliseconds: 600));
    }
  }

  void _beginPurchase() {
    _purchaseAttempt++;
    _attemptLive = true;
    _isPurchasing = true;
    _lastMessage = null;
    _armWatchdog(const Duration(seconds: 12));
    notifyListeners();
  }

  void _armWatchdog(Duration delay) {
    _purchaseWatchdog?.cancel();
    final attempt = _purchaseAttempt;
    _purchaseWatchdog = Timer(delay, () {
      if (!_isPurchasing || attempt != _purchaseAttempt) return;
      if (!_isResumed) {
        _armWatchdog(const Duration(seconds: 5));
        return;
      }
      _finishAttempt(failed: false);
    });
  }

  void _failPurchase() => _finishAttempt(failed: true);

  void _finishAttempt({required bool failed}) {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    final live = _attemptLive || _isPurchasing;
    _attemptLive = false;
    _isPurchasing = false;
    if (failed && live) _lastMessage = 'purchaseFailed';
    notifyListeners();
  }

  void _onBillingError() {
    if (!_attemptLive && !_isPurchasing) return;
    _failPurchase();
  }

  void _onBillingCanceled() {
    if (!_attemptLive && !_isPurchasing) return;
    _finishAttempt(failed: false);
  }

  void _stopPurchaseUi() {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    _attemptLive = false;
    _isPurchasing = false;
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = null;
    final purchaseId = purchase.purchaseID ?? '${purchase.productID}_${purchase.transactionDate}';
    if (_processedPurchaseIds.contains(purchaseId)) {
      _stopPurchaseUi();
      notifyListeners();
      return;
    }

    if (IapConstants.isRemoveAdsProduct(purchase.productID)) {
      _ownedItems.add('remove_ads');
      _processedPurchaseIds.add(purchaseId);
      _lastMessage = 'removeAdsUnlocked';
    } else {
      final base = IapConstants.coinsForProduct(purchase.productID);
      if (base > 0) {
        final packIndex = IapConstants.coinPackIds.indexOf(purchase.productID);
        final isHotDeal = packIndex == weeklyHotDealPackIndex;
        var bonus = 0;
        if (_firstPurchaseBonusAvailable) {
          bonus += IapConstants.bonusCoinsForPack(packIndex, isFirstPurchase: true, isHotDeal: false);
          _firstPurchaseBonusAvailable = false;
          await StorageService.instance.saveBool(_firstPurchaseBonusKey, true);
        }
        if (isHotDeal) {
          bonus += IapConstants.bonusCoinsForPack(packIndex, isFirstPurchase: false, isHotDeal: true);
        }
        final total = base + bonus;
        _coins += total;
        _processedPurchaseIds.add(purchaseId);
        _lastMessage = bonus > 0 ? 'coinsAddedWithBonus' : 'coinsAdded';
        _emitCoinEarned(total, bonus > 0 ? 'coinsAddedWithBonus' : 'coinsAdded');
      }
    }

    _stopPurchaseUi();
    await _saveLocal();
    notifyListeners();
  }

  Future<bool> claimDailyReward() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    if (last == today) return false;

    await _updateLoginStreak(today);

    final streakBonus = (_loginStreak.clamp(1, 7) - 1) * 2;
    final amount = IapConstants.dailyLoginReward + streakBonus;
    _coins += amount;
    await StorageService.instance.saveString(_lastDailyKey, today);
    _lastMessage = 'dailyRewardClaimed';
    _emitCoinEarned(amount, 'dailyRewardClaimed');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<void> _updateLoginStreak(String today) async {
    final lastStreak = await StorageService.instance.getString(_lastStreakDateKey);
    if (lastStreak == today) return;

    if (lastStreak != null) {
      final parts = lastStreak.split('-');
      if (parts.length == 3) {
        final lastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final todayDate = DateTime.now();
        final diff = todayDate.difference(lastDate).inDays;
        if (diff == 1) {
          _loginStreak++;
        } else if (diff > 1) {
          _loginStreak = 1;
        }
      } else {
        _loginStreak = 1;
      }
    } else {
      _loginStreak = 1;
    }

    await StorageService.instance.saveString(_lastStreakDateKey, today);
    await StorageService.instance.saveInt(_loginStreakKey, _loginStreak);
  }

  Future<bool> hasSpunToday() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastSpinKey);
    return last == today;
  }

  Future<int> spinDailyWheel() async {
    if (await hasSpunToday()) return 0;

    final prize = _pickSpinPrize();
    _coins += prize;
    await StorageService.instance.saveString(_lastSpinKey, _dateKey(DateTime.now()));
    _lastMessage = 'spinRewardEarned';
    _emitCoinEarned(prize, 'spinRewardEarned');
    await _saveLocal();
    notifyListeners();
    return prize;
  }

  int _pickSpinPrize() {
    final totalWeight = IapConstants.spinPrizes.fold<int>(0, (s, e) => s + e.$2);
    var roll = _random.nextInt(totalWeight);
    for (final (coins, weight) in IapConstants.spinPrizes) {
      roll -= weight;
      if (roll < 0) return coins;
    }
    return IapConstants.spinPrizes.first.$1;
  }

  int effectiveCoinsForPackIndex(int packIndex) {
    final base = packIndex >= 0 && packIndex < IapConstants.coinPackAmounts.length
        ? IapConstants.coinPackAmounts[packIndex]
        : 0;
    return base +
        IapConstants.bonusCoinsForPack(
          packIndex,
          isFirstPurchase: _firstPurchaseBonusAvailable,
          isHotDeal: packIndex == weeklyHotDealPackIndex,
        );
  }

  Future<bool> hasClaimedDailyToday() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    return last == today;
  }

  Future<bool> rewardForNoteCreated() => _dailyReward(
        dateKey: _noteRewardDateKey,
        countKey: _noteRewardCountKey,
        max: IapConstants.maxNoteRewardsPerDay,
        amount: IapConstants.noteCreateReward,
        messageKey: 'noteRewardEarned',
      );

  Future<bool> _dailyReward({
    required String dateKey,
    required String countKey,
    required int max,
    required int amount,
    required String messageKey,
  }) async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(dateKey);
    var count = await StorageService.instance.getInt(countKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(dateKey, today);
    }
    if (count >= max) return false;

    _coins += amount;
    count++;
    await StorageService.instance.saveInt(countKey, count);
    _emitCoinEarned(amount, messageKey);
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<void> selectTheme(String themeId) async {
    if (themeId != ShopCatalog.defaultThemeId && !_ownedItems.contains(themeId)) return;
    _activeThemeId = themeId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectBackground(String bgId) async {
    if (bgId != ShopCatalog.defaultBackgroundId && !_ownedItems.contains(bgId)) return;
    _activeBackgroundId = bgId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectSkin(String skinId) async {
    if (skinId != ShopCatalog.defaultSkinId && !_ownedItems.contains(skinId)) return;
    _activeSkinId = skinId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> resetThemeToDefault() => selectTheme(ShopCatalog.defaultThemeId);
  Future<void> resetBackgroundToDefault() => selectBackground(ShopCatalog.defaultBackgroundId);
  Future<void> resetSkinToDefault() => selectSkin(ShopCatalog.defaultSkinId);

  void clearLastMessage() => _lastMessage = null;
  void clearCoinEvent() => _lastCoinEvent = null;

  void _emitCoinEarned(int amount, String messageKey) {
    if (amount <= 0) return;
    _lastCoinEvent = ShopCoinEvent(amount: amount, messageKey: messageKey);
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  @override
  void dispose() {
    _purchaseWatchdog?.cancel();
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    _billing.dispose();
    super.dispose();
  }
}
