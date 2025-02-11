import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Animated,
  Platform,
  Keyboard
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';

const EventSearchBar = ({
  value,
  onChangeText,
  onFocus,
  onBlur,
  onClear,
  placeholder = 'Search events...',
  style
}) => {
  const { colors, typography } = useTheme();
  const [isFocused, setIsFocused] = useState(false);
  const [clearButtonOpacity] = useState(new Animated.Value(0));

  useEffect(() => {
    Animated.timing(clearButtonOpacity, {
      toValue: value ? 1 : 0,
      duration: 200,
      useNativeDriver: true,
    }).start();
  }, [value]);

  const handleFocus = () => {
    setIsFocused(true);
    onFocus?.();
  };

  const handleBlur = () => {
    setIsFocused(false);
    onBlur?.();
  };

  const handleClear = () => {
    onChangeText?.('');
    onClear?.();
    Keyboard.dismiss();
  };

  return (
    <View
      style={[
        styles.container,
        {
          backgroundColor: colors.surface,
          borderColor: isFocused ? colors.primary : colors.border
        },
        style
      ]}
    >
      <Icon
        name="search"
        size={20}
        color={isFocused ? colors.primary : colors.textSecondary}
        style={styles.searchIcon}
      />

      <TextInput
        value={value}
        onChangeText={onChangeText}
        onFocus={handleFocus}
        onBlur={handleBlur}
        placeholder={placeholder}
        placeholderTextColor={colors.textSecondary}
        style={[
          styles.input,
          {
            color: colors.text,
            ...typography.body
          }
        ]}
        returnKeyType="search"
        autoCapitalize="none"
        autoCorrect={false}
      />

      <Animated.View
        style={[
          styles.clearButton,
          { opacity: clearButtonOpacity }
        ]}
        pointerEvents={value ? 'auto' : 'none'}
      >
        <TouchableOpacity
          onPress={handleClear}
          hitSlop={{ top: 10, right: 10, bottom: 10, left: 10 }}
        >
          <Icon
            name="close-circle"
            size={20}
            color={colors.textSecondary}
          />
        </TouchableOpacity>
      </Animated.View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 12,
    paddingHorizontal: 16,
    height: 48,
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
  searchIcon: {
    marginRight: 12,
  },
  input: {
    flex: 1,
    fontSize: 16,
    padding: 0,
    height: '100%',
  },
  clearButton: {
    marginLeft: 12,
  },
});

export default EventSearchBar;
