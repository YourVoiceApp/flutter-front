package com.love.yourvoiceback.billing;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.auth.oauth2.AccessToken;
import com.google.auth.oauth2.GoogleCredentials;
import com.love.yourvoiceback.common.exception.ApiException;
import com.love.yourvoiceback.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;

@Component
public class GooglePlayPurchaseVerifier {

    private static final String ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher";
    private static final String GOOGLE_PLAY_API_BASE_URL = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Value("${billing.google-play.package-name:}")
    private String packageName;

    @Value("${billing.google-play.service-account-json:}")
    private String serviceAccountJson;

    @Value("${billing.google-play.service-account-path:}")
    private String serviceAccountPath;

    public VerificationResult verifyProductPurchase(String productId, String purchaseToken) {
        validateConfiguration();

        try {
            AccessToken accessToken = loadCredentials().refreshAccessToken();
            HttpRequest request = HttpRequest.newBuilder(buildVerificationUri(productId, purchaseToken))
                    .header("Authorization", "Bearer " + accessToken.getTokenValue())
                    .header("Accept", "application/json")
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return parseVerificationResponse(response, productId);
        } catch (ApiException exception) {
            throw exception;
        } catch (IOException | InterruptedException exception) {
            if (exception instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_PURCHASE_VERIFICATION_FAILED, exception);
        }
    }

    private void validateConfiguration() {
        if (!StringUtils.hasText(packageName)) {
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_NOT_CONFIGURED, "Google Play package name is missing");
        }
        if (!StringUtils.hasText(serviceAccountJson) && !StringUtils.hasText(serviceAccountPath)) {
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_NOT_CONFIGURED, "Google Play service account credentials are missing");
        }
    }

    private GoogleCredentials loadCredentials() throws IOException {
        try (InputStream inputStream = openCredentialStream()) {
            return GoogleCredentials.fromStream(inputStream)
                    .createScoped(List.of(ANDROID_PUBLISHER_SCOPE));
        }
    }

    private InputStream openCredentialStream() throws IOException {
        if (StringUtils.hasText(serviceAccountJson)) {
            return new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8));
        }
        return Files.newInputStream(Path.of(serviceAccountPath));
    }

    private URI buildVerificationUri(String productId, String purchaseToken) {
        return URI.create(
                GOOGLE_PLAY_API_BASE_URL
                        + "/" + encode(packageName)
                        + "/purchases/products/" + encode(productId)
                        + "/tokens/" + encode(purchaseToken)
        );
    }

    private VerificationResult parseVerificationResponse(HttpResponse<String> response, String expectedProductId) throws IOException {
        int statusCode = response.statusCode();
        if (statusCode == 404) {
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_PURCHASE_INVALID, "Purchase token was not found in Google Play");
        }
        if (statusCode == 401 || statusCode == 403) {
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_PURCHASE_VERIFICATION_FAILED, "Google Play API rejected the service account");
        }
        if (statusCode < 200 || statusCode >= 300) {
            throw ApiException.error(
                    ErrorCode.GOOGLE_PLAY_PURCHASE_VERIFICATION_FAILED,
                    "Google Play API returned status " + statusCode
            );
        }

        JsonNode body = objectMapper.readTree(response.body());
        int purchaseState = body.path("purchaseState").asInt(-1);
        String productId = body.path("productId").asText("");
        long purchaseTimeMillis = body.path("purchaseTimeMillis").asLong(0L);

        if (purchaseState != 0) {
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_PURCHASE_INVALID, "Google Play purchase is not completed");
        }
        if (!expectedProductId.equals(productId)) {
            throw ApiException.error(ErrorCode.GOOGLE_PLAY_PURCHASE_INVALID, "Google Play product id does not match the order");
        }

        LocalDateTime purchasedAt = purchaseTimeMillis > 0
                ? LocalDateTime.ofInstant(Instant.ofEpochMilli(purchaseTimeMillis), ZoneOffset.UTC)
                : LocalDateTime.now(ZoneOffset.UTC);

        return new VerificationResult(
                body.path("orderId").asText(null),
                productId,
                purchaseState,
                body.path("acknowledgementState").asInt(-1),
                purchasedAt
        );
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    public record VerificationResult(
            String googleOrderId,
            String productId,
            int purchaseState,
            int acknowledgementState,
            LocalDateTime purchasedAt
    ) {
    }
}
