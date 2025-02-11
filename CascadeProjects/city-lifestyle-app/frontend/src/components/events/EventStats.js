import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Platform
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';
import { formatNumber } from '../../utils/numberUtils';

const EventStats = ({
  stats,
  onStatPress,
  style
}) => {
  const { colors, typography } = useTheme();

  const renderStat = (stat) => (
    <TouchableOpacity
      key={stat.id}
      style={[
        styles.statContainer,
        {
          backgroundColor: colors.surface,
          borderColor: colors.border
        }
      ]}
      onPress={() => onStatPress?.(stat.id)}
      activeOpacity={0.8}
    >
      <View
        style={[
          styles.iconContainer,
          {
            backgroundColor: colors.primaryLight
          }
        ]}
      >
        <Icon
          name={stat.icon}
          size={20}
          color={colors.primary}
        />
      </View>

      <View style={styles.textContainer}>
        <Text
          style={[
            styles.value,
            {
              color: colors.text,
              ...typography.h3
            }
          ]}
        >
          {formatNumber(stat.value)}
        </Text>
        <Text
          style={[
            styles.label,
            {
              color: colors.textSecondary,
              ...typography.caption
            }
          ]}
        >
          {stat.label}
        </Text>
      </View>

      {stat.trend && (
        <View
          style={[
            styles.trendContainer,
            {
              backgroundColor:
                stat.trend > 0
                  ? colors.successLight
                  : colors.errorLight
            }
          ]}
        >
          <Icon
            name={stat.trend > 0 ? 'trending-up' : 'trending-down'}
            size={16}
            color={
              stat.trend > 0
                ? colors.success
                : colors.error
            }
          />
          <Text
            style={[
              styles.trendValue,
              {
                color:
                  stat.trend > 0
                    ? colors.success
                    : colors.error
              }
            ]}
          >
            {Math.abs(stat.trend)}%
          </Text>
        </View>
      )}
    </TouchableOpacity>
  );

  return (
    <View style={[styles.container, style]}>
      {stats.map(renderStat)}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  statContainer: {
    flex: 1,
    minWidth: 140,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    gap: 12,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textContainer: {
    flex: 1,
  },
  value: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 2,
  },
  label: {
    fontSize: 12,
  },
  trendContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    gap: 4,
  },
  trendValue: {
    fontSize: 12,
    fontWeight: '500',
  },
});

export default EventStats;
