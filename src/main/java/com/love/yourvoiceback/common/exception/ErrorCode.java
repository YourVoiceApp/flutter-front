package com.love.yourvoiceback.common.exception;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    INVALID_REQUEST(HttpStatus.BAD_REQUEST, "Invalid request"),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "Internal server error"),

    EMAIL_ALREADY_REGISTERED(HttpStatus.CONFLICT, "Email already registered"),
    EMAIL_NOT_VERIFIED(HttpStatus.BAD_REQUEST, "Email verification is required"),
    EMAIL_VERIFICATION_CODE_INVALID(HttpStatus.BAD_REQUEST, "Invalid email verification code"),
    EMAIL_VERIFICATION_CODE_EXPIRED(HttpStatus.BAD_REQUEST, "Email verification code expired"),
    EMAIL_VERIFICATION_SEND_FAILED(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to send email verification message"),
    NICKNAME_ALREADY_TAKEN(HttpStatus.CONFLICT, "Nickname already taken"),
    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "Invalid email or password"),
    PASSWORD_LOGIN_NOT_AVAILABLE(HttpStatus.BAD_REQUEST, "Password login is not available for this account"),

    INVALID_REFRESH_TOKEN(HttpStatus.UNAUTHORIZED, "Invalid refresh token"),
    REFRESH_TOKEN_NOT_FOUND(HttpStatus.UNAUTHORIZED, "Refresh token not found"),
    REFRESH_TOKEN_EXPIRED(HttpStatus.UNAUTHORIZED, "Refresh token expired"),
    REFRESH_TOKEN_USER_MISMATCH(HttpStatus.UNAUTHORIZED, "Refresh token user mismatch"),

    INVALID_GOOGLE_ID_TOKEN(HttpStatus.UNAUTHORIZED, "Invalid google id token payload"),
    GOOGLE_TOKEN_AUDIENCE_MISMATCH(HttpStatus.UNAUTHORIZED, "Google token audience mismatch"),
    GOOGLE_EMAIL_NOT_VERIFIED(HttpStatus.BAD_REQUEST, "Google email is not verified"),
    GOOGLE_PLAY_NOT_CONFIGURED(HttpStatus.INTERNAL_SERVER_ERROR, "Google Play billing is not configured"),
    GOOGLE_PLAY_PURCHASE_INVALID(HttpStatus.BAD_REQUEST, "Google Play purchase is invalid"),
    GOOGLE_PLAY_PURCHASE_VERIFICATION_FAILED(HttpStatus.BAD_GATEWAY, "Failed to verify Google Play purchase"),

    INVALID_KAKAO_USER_RESPONSE(HttpStatus.UNAUTHORIZED, "Invalid kakao user response"),
    KAKAO_EMAIL_NOT_VERIFIED(HttpStatus.BAD_REQUEST, "Kakao account email must be available and verified"),
    KAKAO_PROFILE_FETCH_FAILED(HttpStatus.UNAUTHORIZED, "Failed to fetch kakao user profile"),

    CURRENT_PASSWORD_REQUIRED(HttpStatus.BAD_REQUEST, "Current password is required"),
    CURRENT_PASSWORD_INCORRECT(HttpStatus.BAD_REQUEST, "Current password is incorrect"),
    USER_NOT_FOUND(HttpStatus.NOT_FOUND, "User not found"),
    PAYMENT_ORDER_NOT_FOUND(HttpStatus.NOT_FOUND, "Payment order not found"),
    ROOM_NOT_FOUND(HttpStatus.NOT_FOUND, "Room not found"),
    VOICE_FOLDER_NOT_FOUND(HttpStatus.NOT_FOUND, "Voice folder not found"),
    VOICE_ASSET_NOT_FOUND(HttpStatus.NOT_FOUND, "Voice asset not found"),
    GENERATED_AUDIO_NOT_FOUND(HttpStatus.NOT_FOUND, "Generated audio not found"),
    ROOM_VOICE_SHARE_NOT_FOUND(HttpStatus.NOT_FOUND, "Room voice share not found"),

    SUPERTONE_BAD_REQUEST(HttpStatus.BAD_REQUEST, "Invalid request for Supertone voice cloning"),
    SUPERTONE_UNAUTHORIZED(HttpStatus.BAD_GATEWAY, "Supertone API authentication failed"),
    SUPERTONE_FORBIDDEN(HttpStatus.FORBIDDEN, "Supertone voice cloning is not available for this account"),
    SUPERTONE_FILE_TOO_LARGE(HttpStatus.PAYLOAD_TOO_LARGE, "Voice file must be 3MB or smaller"),
    SUPERTONE_UNSUPPORTED_MEDIA_TYPE(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Only WAV or MP3 files are supported"),
    SUPERTONE_RATE_LIMITED(HttpStatus.TOO_MANY_REQUESTS, "Supertone API rate limit exceeded"),
    SUPERTONE_REQUEST_FAILED(HttpStatus.BAD_GATEWAY, "Failed to create cloned voice via Supertone");

    private final HttpStatus status;
    private final String message;

    ErrorCode(HttpStatus status, String message) {
        this.status = status;
        this.message = message;
    }

    public HttpStatus status() {
        return status;
    }

    public String message() {
        return message;
    }
}
