import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Platform,
  Linking
} from 'react-native';
import MapView, { Marker } from 'react-native-maps';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';

const EventMap = ({
  location,
  placeName,
  onPress,
  style
}) => {
  const { colors, typography } = useTheme();

  const handleDirectionsPress = () => {
    const scheme = Platform.select({
      ios: 'maps:',
      android: 'geo:'
    });
    const url = Platform.select({
      ios: `${scheme}?q=${location.latitude},${location.longitude}`,
      android: `${scheme}${location.latitude},${location.longitude}`
    });

    Linking.openURL(url);
  };

  const initialRegion = {
    latitude: location.latitude,
    longitude: location.longitude,
    latitudeDelta: 0.01,
    longitudeDelta: 0.01
  };

  return (
    <View style={[styles.container, style]}>
      <TouchableOpacity
        style={[
          styles.mapContainer,
          { backgroundColor: colors.surface }
        ]}
        onPress={onPress}
        activeOpacity={0.9}
      >
        <MapView
          style={styles.map}
          initialRegion={initialRegion}
          scrollEnabled={false}
          zoomEnabled={false}
          rotateEnabled={false}
          pitchEnabled={false}
        >
          <Marker
            coordinate={{
              latitude: location.latitude,
              longitude: location.longitude
            }}
            title={placeName}
          />
        </MapView>

        <View
          style={[
            styles.overlay,
            { backgroundColor: colors.surface }
          ]}
        >
          <View style={styles.placeInfo}>
            <Icon
              name="location"
              size={20}
              color={colors.primary}
            />
            <Text
              style={[
                styles.placeName,
                { color: colors.text }
              ]}
              numberOfLines={1}
            >
              {placeName}
            </Text>
          </View>

          <TouchableOpacity
            style={[
              styles.directionsButton,
              { backgroundColor: colors.primary }
            ]}
            onPress={handleDirectionsPress}
          >
            <Icon
              name="directions"
              size={20}
              color={colors.surface}
            />
            <Text
              style={[
                styles.directionsText,
                {
                  color: colors.surface,
                  ...typography.button
                }
              ]}
            >
              Directions
            </Text>
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  mapContainer: {
    borderRadius: 12,
    overflow: 'hidden',
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
  map: {
    width: '100%',
    height: 200,
  },
  overlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: 'rgba(0, 0, 0, 0.1)',
  },
  placeInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    marginRight: 12,
  },
  placeName: {
    fontSize: 16,
    fontWeight: '500',
    marginLeft: 8,
  },
  directionsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    gap: 4,
  },
  directionsText: {
    fontSize: 14,
    fontWeight: '600',
  },
});

export default EventMap;
