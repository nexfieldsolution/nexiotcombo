import 'package:flutter/material.dart';

const primaryColor = Color(0xFF2697FF);
const secondaryColor = Color(0xFF2A2D3E);
const bgColor = Color(0xFF212332);
const accentColor = Color(0xFF00D4FF); // BLE 장치명 등 강조 액센트
const accentBlueColor = Color(0xFF1081E9); // 중요 버튼 / 강조 텍스트
const darkBlueColor = Color(0xFF0153A0);  // 보조 설명 텍스트

const defaultPadding = 16.0;

// Summary screen pagination
const cardsPerSummaryPage = 4;
const badgePerSummaryPage = 20;

// BLE characteristic UUIDs
const bleUuidNonce  = '12345678-1234-1234-1234-123456789ab4'; // READ  — 12-byte nonce
const bleUuidConfig = '12345678-1234-1234-1234-123456789ab2'; // WRITE — encrypted JSON

// ESP32 AP mode default IP
const espApIp = '192.168.4.1';

enum AppSection { summary, monitoring }
