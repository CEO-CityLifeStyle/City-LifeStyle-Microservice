import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Image,
  TouchableOpacity,
  ActivityIndicator
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { useTheme } from '../../hooks/useTheme';
import Icon from '../common/Icon';
import Button from '../common/Button';

const AttendeesList = ({
  eventId,
  attendees,
  loading,
  onApprove,
  onReject,
  isManagement = false,
  style
}) => {
  const navigation = useNavigation();
  const { colors, typography } = useTheme();
  const [showAll, setShowAll] = useState(false);

  const displayedAttendees = showAll
    ? attendees
    : attendees.slice(0, 6);

  const handleUserPress = (userId) => {
    navigation.navigate('Profile', { userId });
  };

  const renderAttendee = ({ item: attendee }) => (
    <View
      style={[
        styles.attendeeContainer,
        { backgroundColor: colors.surface }
      ]}
    >
      <TouchableOpacity
        style={styles.attendeeInfo}
        onPress={() => handleUserPress(attendee.userId)}
      >
        <Image
          source={{ uri: attendee.user.avatar }}
          style={styles.avatar}
        />
        <View style={styles.userInfo}>
          <Text
            style={[
              styles.userName,
              { color: colors.text }
            ]}
          >
            {attendee.user.name}
          </Text>
          <Text
            style={[
              styles.ticketInfo,
              { color: colors.textSecondary }
            ]}
          >
            {attendee.ticketCount} {attendee.ticketCount === 1 ? 'ticket' : 'tickets'}
          </Text>
        </View>
      </TouchableOpacity>

      {isManagement && (
        <View style={styles.actions}>
          {attendee.status === 'waitlisted' && (
            <Button
              title="Approve"
              onPress={() => onApprove(attendee.id)}
              variant="success"
              size="small"
              style={styles.actionButton}
            />
          )}
          <Button
            title="Remove"
            onPress={() => onReject(attendee.id)}
            variant="danger"
            size="small"
            style={styles.actionButton}
          />
        </View>
      )}
    </View>
  );

  const renderHeader = () => (
    <View style={styles.header}>
      <Text
        style={[
          styles.title,
          { color: colors.text, ...typography.subtitle }
        ]}
      >
        Attendees ({attendees.length})
      </Text>
      {attendees.length > 6 && (
        <TouchableOpacity
          onPress={() => setShowAll(!showAll)}
          style={styles.showAllButton}
        >
          <Text
            style={[
              styles.showAllText,
              { color: colors.primary }
            ]}
          >
            {showAll ? 'Show Less' : 'Show All'}
          </Text>
          <Icon
            name={showAll ? 'chevron-up' : 'chevron-down'}
            size={16}
            color={colors.primary}
          />
        </TouchableOpacity>
      )}
    </View>
  );

  if (loading) {
    return (
      <View style={[styles.container, styles.centered, style]}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (attendees.length === 0) {
    return (
      <View style={[styles.container, style]}>
        {renderHeader()}
        <View style={[styles.emptyState, { backgroundColor: colors.surface }]}>
          <Text
            style={[
              styles.emptyText,
              { color: colors.textSecondary }
            ]}
          >
            No attendees yet
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={[styles.container, style]}>
      {renderHeader()}
      <FlatList
        data={displayedAttendees}
        renderItem={renderAttendee}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        showsVerticalScrollIndicator={false}
        scrollEnabled={false}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  centered: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
  },
  showAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  showAllText: {
    fontSize: 14,
    fontWeight: '500',
  },
  list: {
    gap: 8,
  },
  attendeeContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 12,
    borderRadius: 8,
  },
  attendeeInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#E1E1E1',
  },
  userInfo: {
    marginLeft: 12,
    flex: 1,
  },
  userName: {
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 2,
  },
  ticketInfo: {
    fontSize: 14,
  },
  actions: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    minWidth: 80,
  },
  emptyState: {
    padding: 24,
    borderRadius: 8,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
  },
});

export default AttendeesList;
