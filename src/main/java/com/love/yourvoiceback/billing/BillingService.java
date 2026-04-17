package com.love.yourvoiceback.billing;

import com.love.yourvoiceback.billing.dto.request.AdsRemovalConfirmRequest;
import com.love.yourvoiceback.billing.dto.response.AdsRemovalOrderResponse;
import com.love.yourvoiceback.billing.dto.response.AdsRemovalStatusResponse;
import com.love.yourvoiceback.common.exception.ApiException;
import com.love.yourvoiceback.common.exception.ErrorCode;
import com.love.yourvoiceback.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class BillingService {

    public static final String ADS_REMOVAL_PRODUCT_ID = "ads_removal";

    private final PaymentOrderRepository paymentOrderRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final EntitlementRepository entitlementRepository;
    private final GooglePlayPurchaseVerifier googlePlayPurchaseVerifier;

    @Transactional(readOnly = true)
    public AdsRemovalStatusResponse getAdsRemovalStatus(User user) {
        return entitlementRepository.findByUserIdAndCode(user.getId(), Entitlement.EntitlementCode.ADS_FREE)
                .filter(Entitlement::isCurrentlyActive)
                .map(entitlement -> AdsRemovalStatusResponse.of(true, ADS_REMOVAL_PRODUCT_ID, entitlement.getStartedAt()))
                .orElseGet(() -> AdsRemovalStatusResponse.of(false, ADS_REMOVAL_PRODUCT_ID, null));
    }

    @Transactional
    public AdsRemovalOrderResponse createAdsRemovalOrder(User user) {
        if (hasAdsFreeEntitlement(user.getId())) {
            throw ApiException.error(ErrorCode.INVALID_REQUEST, "Ads have already been removed for this account");
        }

        PaymentOrder order = paymentOrderRepository.save(PaymentOrder.builder()
                .user(user)
                .productType(PaymentOrder.ProductType.ADS_REMOVAL)
                .productId(ADS_REMOVAL_PRODUCT_ID)
                .status(PaymentOrder.OrderStatus.CREATED)
                .build());

        return AdsRemovalOrderResponse.from(order, false);
    }

    @Transactional
    public AdsRemovalOrderResponse confirmAdsRemoval(User user, AdsRemovalConfirmRequest request) {
        String purchaseToken = request.purchaseToken() != null ? request.purchaseToken().trim() : null;
        if (!StringUtils.hasText(purchaseToken)) {
            throw ApiException.error(ErrorCode.INVALID_REQUEST, "Purchase token is required");
        }

        PaymentOrder order = paymentOrderRepository.findByIdAndUserId(request.orderId(), user.getId())
                .orElseThrow(() -> ApiException.error(ErrorCode.PAYMENT_ORDER_NOT_FOUND));

        if (order.getProductType() != PaymentOrder.ProductType.ADS_REMOVAL) {
            throw ApiException.error(ErrorCode.INVALID_REQUEST, "Unsupported billing product type");
        }

        if (order.getStatus() == PaymentOrder.OrderStatus.PAID) {
            return AdsRemovalOrderResponse.from(order, hasAdsFreeEntitlement(user.getId()));
        }

        if (paymentTransactionRepository.existsByProviderAndProviderTransactionId(
                PaymentTransaction.PaymentProvider.GOOGLE,
                purchaseToken
        )) {
            throw ApiException.error(ErrorCode.INVALID_REQUEST, "Purchase token has already been used");
        }

        GooglePlayPurchaseVerifier.VerificationResult verificationResult =
                googlePlayPurchaseVerifier.verifyProductPurchase(order.getProductId(), purchaseToken);

        LocalDateTime now = verificationResult.purchasedAt();
        order.markPaid(now);

        paymentTransactionRepository.save(PaymentTransaction.builder()
                .order(order)
                .provider(PaymentTransaction.PaymentProvider.GOOGLE)
                .providerTransactionId(purchaseToken)
                .verifiedAt(now)
                .build());

        Entitlement entitlement = entitlementRepository.findByUserIdAndCode(user.getId(), Entitlement.EntitlementCode.ADS_FREE)
                .orElseGet(() -> Entitlement.builder()
                        .user(user)
                        .code(Entitlement.EntitlementCode.ADS_FREE)
                        .active(true)
                        .startedAt(now)
                        .build());
        entitlement.activate(now);
        entitlementRepository.save(entitlement);

        return AdsRemovalOrderResponse.from(order, true);
    }

    private boolean hasAdsFreeEntitlement(Long userId) {
        return entitlementRepository.findByUserIdAndCode(userId, Entitlement.EntitlementCode.ADS_FREE)
                .map(Entitlement::isCurrentlyActive)
                .orElse(false);
    }
}
