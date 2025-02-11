import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  Platform
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';
import Button from '../common/Button';

const RSVPButton = ({
  status,
  ticketCount,
  onTicketCountChange,
  onPress,
  disabled,
  style
}) => {
  const { colors, typography } = useTheme();
  const [showTicketModal, setShowTicketModal] = useState(false);

  const getButtonConfig = () => {
    switch (status) {
      case 'confirmed':
        return {
          text: 'Going',
          icon: 'check',
          variant: 'filled',
          color: colors.success
        };
      case 'waitlisted':
        return {
          text: 'Waitlisted',
          icon: 'time',
          variant: 'outlined',
          color: colors.warning
        };
      case 'declined':
        return {
          text: 'Declined',
          icon: 'close',
          variant: 'outlined',
          color: colors.error
        };
      default:
        return {
          text: 'RSVP',
          icon: 'add',
          variant: 'filled',
          color: colors.primary
        };
    }
  };

  const config = getButtonConfig();

  const handlePress = () => {
    if (!status) {
      setShowTicketModal(true);
    } else {
      onPress();
    }
  };

  const handleTicketSelect = (count) => {
    onTicketCountChange(count);
    setShowTicketModal(false);
    onPress();
  };

  const renderTicketModal = () => (
    <Modal
      visible={showTicketModal}
      transparent
      animationType="slide"
      onRequestClose={() => setShowTicketModal(false)}
    >
      <View style={styles.modalOverlay}>
        <View
          style={[
            styles.modalContent,
            { backgroundColor: colors.surface }
          ]}
        >
          <Text
            style={[
              styles.modalTitle,
              { color: colors.text, ...typography.title }
            ]}
          >
            How many tickets?
          </Text>

          <View style={styles.ticketSelector}>
            {[1, 2, 3, 4].map((count) => (
              <TouchableOpacity
                key={count}
                style={[
                  styles.ticketOption,
                  ticketCount === count && {
                    backgroundColor: colors.primaryLight
                  }
                ]}
                onPress={() => handleTicketSelect(count)}
              >
                <Text
                  style={[
                    styles.ticketCount,
                    {
                      color: ticketCount === count
                        ? colors.primary
                        : colors.text
                    }
                  ]}
                >
                  {count}
                </Text>
                <Text
                  style={[
                    styles.ticketLabel,
                    {
                      color: ticketCount === count
                        ? colors.primary
                        : colors.textSecondary
                    }
                  ]}
                >
                  {count === 1 ? 'ticket' : 'tickets'}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <Button
            title="Cancel"
            onPress={() => setShowTicketModal(false)}
            variant="text"
            style={styles.cancelButton}
          />
        </View>
      </View>
    </Modal>
  );

  return (
    <View style={[styles.container, style]}>
      <TouchableOpacity
        style={[
          styles.button,
          styles[config.variant],
          {
            backgroundColor:
              config.variant === 'filled'
                ? config.color
                : colors.surface,
            borderColor: config.color,
            opacity: disabled ? 0.5 : 1
          }
        ]}
        onPress={handlePress}
        disabled={disabled}
        activeOpacity={0.7}
      >
        <Icon
          name={config.icon}
          size={20}
          color={
            config.variant === 'filled'
              ? colors.surface
              : config.color
          }
        />
        <Text
          style={[
            styles.buttonText,
            {
              color:
                config.variant === 'filled'
                  ? colors.surface
                  : config.color,
              ...typography.button
            }
          ]}
        >
          {config.text}
        </Text>
        {status === 'confirmed' && (
          <View
            style={[
              styles.badge,
              { backgroundColor: colors.surface }
            ]}
          >
            <Text
              style={[
                styles.badgeText,
                { color: config.color }
              ]}
            >
              {ticketCount}
            </Text>
          </View>
        )}
      </TouchableOpacity>

      {renderTicketModal()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    borderRadius: 8,
    borderWidth: 2,
    gap: 8,
  },
  filled: {},
  outlined: {
    backgroundColor: 'transparent',
  },
  buttonText: {
    fontSize: 16,
    fontWeight: '600',
  },
  badge: {
    position: 'absolute',
    right: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
    minWidth: 24,
    alignItems: 'center',
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    padding: 24,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: -2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  modalTitle: {
    textAlign: 'center',
    marginBottom: 24,
  },
  ticketSelector: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  ticketOption: {
    flex: 1,
    margin: 4,
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  ticketCount: {
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 4,
  },
  ticketLabel: {
    fontSize: 12,
  },
  cancelButton: {
    marginTop: 8,
  },
});

export default RSVPButton;
