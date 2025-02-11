import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Platform
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';

const STATUS_CONFIG = {
  confirmed: {
    icon: 'check-circle',
    label: 'Confirmed',
    colors: {
      background: 'successLight',
      text: 'success',
      icon: 'success'
    }
  },
  waitlisted: {
    icon: 'time',
    label: 'Waitlisted',
    colors: {
      background: 'warningLight',
      text: 'warning',
      icon: 'warning'
    }
  },
  cancelled: {
    icon: 'close-circle',
    label: 'Cancelled',
    colors: {
      background: 'errorLight',
      text: 'error',
      icon: 'error'
    }
  },
  pending: {
    icon: 'clock',
    label: 'Pending',
    colors: {
      background: 'primaryLight',
      text: 'primary',
      icon: 'primary'
    }
  }
};

const RSVPStatusBadge = ({
  status,
  size = 'medium',
  style
}) => {
  const { colors } = useTheme();
  const config = STATUS_CONFIG[status] || STATUS_CONFIG.pending;

  const getSizeStyles = () => {
    switch (size) {
      case 'small':
        return {
          container: {
            paddingVertical: 4,
            paddingHorizontal: 8,
            borderRadius: 8,
          },
          icon: 14,
          text: 12
        };
      case 'large':
        return {
          container: {
            paddingVertical: 8,
            paddingHorizontal: 16,
            borderRadius: 12,
          },
          icon: 20,
          text: 16
        };
      default: // medium
        return {
          container: {
            paddingVertical: 6,
            paddingHorizontal: 12,
            borderRadius: 10,
          },
          icon: 16,
          text: 14
        };
    }
  };

  const sizeStyles = getSizeStyles();

  return (
    <View
      style={[
        styles.container,
        sizeStyles.container,
        {
          backgroundColor: colors[config.colors.background]
        },
        style
      ]}
    >
      <Icon
        name={config.icon}
        size={sizeStyles.icon}
        color={colors[config.colors.icon]}
        style={styles.icon}
      />
      <Text
        style={[
          styles.text,
          {
            color: colors[config.colors.text],
            fontSize: sizeStyles.text
          }
        ]}
      >
        {config.label}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.1,
        shadowRadius: 2,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  icon: {
    marginRight: 4,
  },
  text: {
    fontWeight: '600',
  },
});

export default RSVPStatusBadge;
