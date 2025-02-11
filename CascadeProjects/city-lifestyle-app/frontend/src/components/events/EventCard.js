import React from 'react';
import {
  View,
  Text,
  Image,
  StyleSheet,
  TouchableOpacity,
  Dimensions
} from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import { formatDate, formatTime } from '../../utils/dateUtils';
import { truncateText } from '../../utils/textUtils';
import Icon from '../common/Icon';
import RSVPStatusBadge from './RSVPStatusBadge';

const { width } = Dimensions.get('window');
const GRID_SPACING = 12;
const GRID_COLUMNS = 2;
const GRID_ITEM_WIDTH = (width - (GRID_COLUMNS + 1) * GRID_SPACING) / GRID_COLUMNS;

const EventCard = ({
  event,
  onPress,
  viewType = 'grid',
  style
}) => {
  const { colors, typography } = useTheme();

  const {
    title,
    description,
    startTime,
    images,
    place,
    category,
    price,
    rsvpStatus,
    attendees
  } = event;

  const isGrid = viewType === 'grid';
  const imageSize = isGrid ? GRID_ITEM_WIDTH : 120;

  const cardStyles = [
    styles.container,
    isGrid ? styles.gridContainer : styles.listContainer,
    { backgroundColor: colors.surface },
    style
  ];

  const renderEventInfo = () => (
    <View style={styles.info}>
      <Text
        style={[
          styles.title,
          { color: colors.text, ...typography.subtitle }
        ]}
        numberOfLines={2}
      >
        {title}
      </Text>

      {!isGrid && (
        <Text
          style={[
            styles.description,
            { color: colors.textSecondary }
          ]}
          numberOfLines={2}
        >
          {truncateText(description, 100)}
        </Text>
      )}

      <View style={styles.details}>
        <View style={styles.detailItem}>
          <Icon name="calendar" size={16} color={colors.textSecondary} />
          <Text
            style={[
              styles.detailText,
              { color: colors.textSecondary }
            ]}
          >
            {formatDate(startTime)}
          </Text>
        </View>

        <View style={styles.detailItem}>
          <Icon name="location" size={16} color={colors.textSecondary} />
          <Text
            style={[
              styles.detailText,
              { color: colors.textSecondary }
            ]}
            numberOfLines={1}
          >
            {place.name}
          </Text>
        </View>

        {!isGrid && (
          <View style={styles.detailItem}>
            <Icon name="category" size={16} color={colors.textSecondary} />
            <Text
              style={[
                styles.detailText,
                { color: colors.textSecondary }
              ]}
            >
              {category}
            </Text>
          </View>
        )}
      </View>

      <View style={styles.footer}>
        <Text
          style={[
            styles.price,
            { color: colors.primary, ...typography.subtitle }
          ]}
        >
          {price.amount > 0 ? `$${price.amount}` : 'Free'}
        </Text>

        {rsvpStatus && (
          <RSVPStatusBadge status={rsvpStatus} />
        )}

        {!isGrid && attendees?.confirmed && (
          <View style={styles.attendees}>
            <Icon name="people" size={16} color={colors.textSecondary} />
            <Text
              style={[
                styles.attendeesCount,
                { color: colors.textSecondary }
              ]}
            >
              {attendees.confirmed.length}
            </Text>
          </View>
        )}
      </View>
    </View>
  );

  return (
    <TouchableOpacity
      style={cardStyles}
      onPress={() => onPress(event)}
      activeOpacity={0.7}
    >
      <Image
        source={{ uri: images[0] }}
        style={[
          styles.image,
          isGrid ? { width: GRID_ITEM_WIDTH } : { width: imageSize },
          { height: imageSize }
        ]}
        resizeMode="cover"
      />
      {renderEventInfo()}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 12,
    overflow: 'hidden',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  gridContainer: {
    width: GRID_ITEM_WIDTH,
    marginBottom: GRID_SPACING,
  },
  listContainer: {
    flexDirection: 'row',
    marginBottom: GRID_SPACING,
  },
  image: {
    backgroundColor: '#E1E1E1',
  },
  info: {
    padding: 12,
    flex: 1,
  },
  title: {
    marginBottom: 4,
  },
  description: {
    fontSize: 14,
    marginBottom: 8,
  },
  details: {
    gap: 8,
  },
  detailItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  detailText: {
    fontSize: 12,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 12,
  },
  price: {
    fontSize: 16,
    fontWeight: '600',
  },
  attendees: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  attendeesCount: {
    fontSize: 12,
  },
});

export default EventCard;
