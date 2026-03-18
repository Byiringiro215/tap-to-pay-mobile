import React from 'react';
import { View, Text, StyleSheet, ScrollView, RefreshControl, TouchableOpacity } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, borderRadius, spacing, fontSize } from '../theme';
import { useApp } from '../context/AppContext';
import { GlassCard } from '../components/GlassCard';

export function DashboardScreen() {
    const insets = useSafeAreaInsets();
    const {
        userRole,
        isConnected,
        mqttStatus,
        backendStatus,
        lastScannedUid,
        currentCardData,
        topupHistory,
        purchaseHistory,
        refreshHistory,
        logout,
    } = useApp();

    const [refreshing, setRefreshing] = React.useState(false);

    const onRefresh = async () => {
        setRefreshing(true);
        await refreshHistory();
        setRefreshing(false);
    };

    const totalTopups = topupHistory.reduce((sum, tx) => sum + tx.amount, 0);
    const totalSpent = purchaseHistory.reduce((sum, tx) => sum + tx.amount, 0);
    const recentTx = [...topupHistory, ...purchaseHistory]
        .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
        .slice(0, 5);

    return (
        <ScrollView
            style={[styles.container, { paddingTop: insets.top }]}
            contentContainerStyle={styles.contentContainer}
            showsVerticalScrollIndicator={false}
            refreshControl={
                <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />
            }>
            {/* Header */}
            <View style={styles.headerRow}>
                <View>
                    <Text style={styles.sectionTitle}>📊 Dashboard</Text>
                    <Text style={styles.sectionSubtitle}>
                        {userRole === 'admin' ? 'Administrator' : 'User'} overview
                    </Text>
                </View>
                <View style={[styles.connDot, isConnected && styles.connDotOnline]} />
            </View>

            {/* Card Info */}
            <GlassCard title="💳 Active Card" style={{ marginBottom: spacing.xl }}>
                {currentCardData ? (
                    <>
                        <View style={styles.statRow}>
                            <Text style={styles.statLabel}>Holder</Text>
                            <Text style={styles.statValue}>{currentCardData.holderName}</Text>
                        </View>
                        <View style={styles.statRow}>
                            <Text style={styles.statLabel}>UID</Text>
                            <Text style={[styles.statValue, styles.mono]}>{currentCardData.uid}</Text>
                        </View>
                        <View style={styles.statRow}>
                            <Text style={styles.statLabel}>Balance</Text>
                            <Text style={[styles.statValue, { color: colors.primary }]}>
                                ${currentCardData.balance.toFixed(2)}
                            </Text>
                        </View>
                        <View style={styles.statRow}>
                            <Text style={styles.statLabel}>Passcode</Text>
                            <Text style={[styles.statValue, { color: currentCardData.passcodeSet ? colors.success : colors.warning }]}>
                                {currentCardData.passcodeSet ? '🔒 Protected' : '⚠️ Not Set'}
                            </Text>
                        </View>
                    </>
                ) : (
                    <View style={styles.emptyCard}>
                        <Text style={styles.emptyIcon}>📡</Text>
                        <Text style={styles.emptyText}>
                            {lastScannedUid ? 'Loading card data...' : 'Scan your RFID card to see details'}
                        </Text>
                    </View>
                )}
            </GlassCard>

            {/* Summary Stats */}
            <View style={styles.statsGrid}>
                <View style={styles.statCard}>
                    <Text style={styles.statCardIcon}>💰</Text>
                    <Text style={styles.statCardValue}>{topupHistory.length}</Text>
                    <Text style={styles.statCardLabel}>Top-Ups</Text>
                </View>
                <View style={styles.statCard}>
                    <Text style={styles.statCardIcon}>🛍️</Text>
                    <Text style={styles.statCardValue}>{purchaseHistory.length}</Text>
                    <Text style={styles.statCardLabel}>Purchases</Text>
                </View>
                <View style={styles.statCard}>
                    <Text style={styles.statCardIcon}>📈</Text>
                    <Text style={styles.statCardValue}>${totalTopups.toFixed(0)}</Text>
                    <Text style={styles.statCardLabel}>Total Topped Up</Text>
                </View>
                <View style={styles.statCard}>
                    <Text style={styles.statCardIcon}>💸</Text>
                    <Text style={styles.statCardValue}>${totalSpent.toFixed(0)}</Text>
                    <Text style={styles.statCardLabel}>Total Spent</Text>
                </View>
            </View>

            {/* System Status */}
            <GlassCard title="🔌 Connection Status" style={{ marginBottom: spacing.xl }}>
                <View style={styles.statusRow}>
                    <View style={[styles.dot, { backgroundColor: backendStatus ? colors.success : colors.danger }]} />
                    <Text style={styles.statusLabel}>Backend Server</Text>
                    <Text style={[styles.statusVal, { color: backendStatus ? colors.success : colors.danger }]}>
                        {backendStatus ? 'Online' : 'Offline'}
                    </Text>
                </View>
                <View style={styles.statusRow}>
                    <View style={[styles.dot, { backgroundColor: mqttStatus ? colors.success : colors.danger }]} />
                    <Text style={styles.statusLabel}>MQTT Broker</Text>
                    <Text style={[styles.statusVal, { color: mqttStatus ? colors.success : colors.danger }]}>
                        {mqttStatus ? 'Connected' : 'Disconnected'}
                    </Text>
                </View>
                <View style={styles.statusRow}>
                    <View style={[styles.dot, { backgroundColor: isConnected ? colors.success : colors.danger }]} />
                    <Text style={styles.statusLabel}>WebSocket</Text>
                    <Text style={[styles.statusVal, { color: isConnected ? colors.success : colors.danger }]}>
                        {isConnected ? 'Connected' : 'Disconnected'}
                    </Text>
                </View>
            </GlassCard>

            {/* Recent Transactions */}
            <GlassCard title="🕐 Recent Transactions" style={{ marginBottom: spacing.xl }}>
                {recentTx.length === 0 ? (
                    <View style={styles.emptyCard}>
                        <Text style={styles.emptyIcon}>📭</Text>
                        <Text style={styles.emptyText}>No transactions yet</Text>
                    </View>
                ) : (
                    recentTx.map(tx => (
                        <View key={tx._id} style={styles.txRow}>
                            <Text style={styles.txIcon}>{tx.type === 'topup' ? '↑' : '↓'}</Text>
                            <View style={styles.txInfo}>
                                <Text style={styles.txDesc} numberOfLines={1}>{tx.description}</Text>
                                <Text style={styles.txTime}>
                                    {new Date(tx.timestamp).toLocaleDateString()} · {tx.terminalId}
                                </Text>
                            </View>
                            <Text style={[styles.txAmt, tx.type === 'topup' ? styles.positive : styles.negative]}>
                                {tx.type === 'topup' ? '+' : '-'}${tx.amount.toFixed(2)}
                            </Text>
                        </View>
                    ))
                )}
            </GlassCard>

            {/* Logout */}
            <TouchableOpacity style={styles.logoutBtn} onPress={logout}>
                <Text style={styles.logoutText}>🚪 Logout</Text>
            </TouchableOpacity>

            <View style={{ height: 100 }} />
        </ScrollView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.bgDark },
    contentContainer: { padding: spacing.xl },
    headerRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: spacing.xxl,
    },
    sectionTitle: { fontSize: fontSize.title, fontWeight: '700', color: colors.textMain, marginBottom: spacing.xs },
    sectionSubtitle: { fontSize: fontSize.md, color: colors.textMuted },
    connDot: { width: 12, height: 12, borderRadius: 6, backgroundColor: colors.textMuted, marginTop: 8 },
    connDotOnline: { backgroundColor: colors.success },
    statRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingVertical: spacing.sm,
        borderBottomWidth: 1,
        borderBottomColor: colors.glassBorder,
    },
    statLabel: { fontSize: fontSize.md, color: colors.textMuted },
    statValue: { fontSize: fontSize.md, fontWeight: '600', color: colors.textMain },
    mono: { fontFamily: 'monospace', fontSize: fontSize.sm },
    emptyCard: { alignItems: 'center', paddingVertical: spacing.xxl },
    emptyIcon: { fontSize: 36, marginBottom: spacing.md },
    emptyText: { fontSize: fontSize.md, color: colors.textMuted, textAlign: 'center' },
    statsGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md, marginBottom: spacing.xl },
    statCard: {
        width: '47%',
        backgroundColor: 'rgba(255,255,255,0.04)',
        borderWidth: 1,
        borderColor: colors.glassBorder,
        borderRadius: borderRadius.lg,
        padding: spacing.lg,
        alignItems: 'center',
    },
    statCardIcon: { fontSize: 28, marginBottom: spacing.sm },
    statCardValue: { fontSize: fontSize.xxl, fontWeight: '700', color: colors.textMain, marginBottom: spacing.xs },
    statCardLabel: { fontSize: fontSize.xs, color: colors.textMuted, textAlign: 'center' },
    statusRow: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: spacing.md,
        borderBottomWidth: 1,
        borderBottomColor: colors.glassBorder,
        gap: spacing.md,
    },
    dot: { width: 10, height: 10, borderRadius: 5 },
    statusLabel: { flex: 1, fontSize: fontSize.md, color: colors.textMain },
    statusVal: { fontSize: fontSize.md, fontWeight: '600' },
    txRow: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: spacing.md,
        borderBottomWidth: 1,
        borderBottomColor: colors.glassBorder,
        gap: spacing.md,
    },
    txIcon: { fontSize: fontSize.xl, fontWeight: '700', color: colors.textMain, width: 24, textAlign: 'center' },
    txInfo: { flex: 1 },
    txDesc: { fontSize: fontSize.md, color: colors.textMain, fontWeight: '500' },
    txTime: { fontSize: fontSize.xs, color: colors.textMuted, marginTop: 2 },
    txAmt: { fontSize: fontSize.md, fontWeight: '700' },
    positive: { color: colors.success },
    negative: { color: colors.danger },
    logoutBtn: {
        paddingVertical: spacing.lg,
        backgroundColor: colors.danger,
        borderRadius: borderRadius.lg,
        alignItems: 'center',
    },
    logoutText: { color: '#fff', fontSize: fontSize.lg, fontWeight: '700' },
});
