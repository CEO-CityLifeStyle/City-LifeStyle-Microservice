import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Platform,
  Modal
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';
import Button from '../common/Button';
import { formatDate, formatTime } from '../../utils/dateUtils';

const CustomDateTimePicker = ({
  label,
  value,
  onChange,
  minimumDate,
  maximumDate,
  error,
  style
}) => {
  const { colors, typography } = useTheme();
  const [showPicker, setShowPicker] = useState(false);
  const [mode, setMode] = useState('date');
  const [tempDate, setTempDate] = useState(value);

  const handlePress = (newMode) => {
    setMode(newMode);
    setTempDate(value);
    setShowPicker(true);
  };

  const handleChange = (event, selectedDate) => {
    if (Platform.OS === 'android') {
      setShowPicker(false);
    }

    if (selectedDate) {
      setTempDate(selectedDate);
      if (Platform.OS === 'ios') {
        // On iOS, we wait for the "Done" button
        return;
      }
      onChange(selectedDate);
    }
  };

  const handleIOSConfirm = () => {
    setShowPicker(false);
    onChange(tempDate);
  };

  const handleIOSCancel = () => {
    setShowPicker(false);
    setTempDate(value);
  };

  const renderIOSPicker = () => (
    <Modal
      visible={showPicker}
      transparent
      animationType="slide"
    >
      <View style={styles.modalOverlay}>
        <View
          style={[
            styles.modalContent,
            { backgroundColor: colors.surface }
          ]}
        >
          <View style={styles.modalHeader}>
            <Button
              title="Cancel"
              onPress={handleIOSCancel}
              variant="text"
            />
            <Text
              style={[
                styles.modalTitle,
                { color: colors.text }
              ]}
            >
              {mode === 'date' ? 'Select Date' : 'Select Time'}
            </Text>
            <Button
              title="Done"
              onPress={handleIOSConfirm}
              variant="text"
            />
          </View>

          <DateTimePicker
            value={tempDate}
            mode={mode}
            display="spinner"
            onChange={handleChange}
            minimumDate={minimumDate}
            maximumDate={maximumDate}
            style={styles.iosPicker}
          />
        </View>
      </View>
    </Modal>
  );

  const renderAndroidPicker = () => {
    if (!showPicker) return null;

    return (
      <DateTimePicker
        value={value}
        mode={mode}
        is24Hour={true}
        display="default"
        onChange={handleChange}
        minimumDate={minimumDate}
        maximumDate={maximumDate}
      />
    );
  };

  return (
    <View style={[styles.container, style]}>
      <Text
        style={[
          styles.label,
          { color: error ? colors.error : colors.text }
        ]}
      >
        {label}
      </Text>

      <View style={styles.pickerContainer}>
        <TouchableOpacity
          style={[
            styles.button,
            {
              backgroundColor: colors.surface,
              borderColor: error ? colors.error : colors.border
            }
          ]}
          onPress={() => handlePress('date')}
        >
          <Icon
            name="calendar"
            size={20}
            color={colors.text}
          />
          <Text
            style={[
              styles.buttonText,
              { color: colors.text }
            ]}
          >
            {formatDate(value)}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.button,
            {
              backgroundColor: colors.surface,
              borderColor: error ? colors.error : colors.border
            }
          ]}
          onPress={() => handlePress('time')}
        >
          <Icon
            name="time"
            size={20}
            color={colors.text}
          />
          <Text
            style={[
              styles.buttonText,
              { color: colors.text }
            ]}
          >
            {formatTime(value)}
          </Text>
        </TouchableOpacity>
      </View>

      {error && (
        <Text style={[styles.error, { color: colors.error }]}>
          {error}
        </Text>
      )}

      {Platform.OS === 'ios' ? renderIOSPicker() : renderAndroidPicker()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 8,
  },
  pickerContainer: {
    flexDirection: 'row',
    gap: 12,
  },
  button: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    gap: 8,
  },
  buttonText: {
    fontSize: 16,
  },
  error: {
    fontSize: 14,
    marginTop: 4,
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  modalContent: {
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingBottom: Platform.OS === 'ios' ? 40 : 0,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(0, 0, 0, 0.1)',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '600',
  },
  iosPicker: {
    height: 200,
  },
});

export default CustomDateTimePicker;
