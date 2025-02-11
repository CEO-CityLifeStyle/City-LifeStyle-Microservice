# Settings System Documentation

## Overview
The settings system provides a comprehensive solution for managing user preferences, application configuration, and system settings across both local storage and cloud synchronization.

## Current Implementation

### 1. Settings Service

```javascript
// backend/src/services/settingsService.js
class SettingsService {
  constructor(db, cache) {
    this.db = db;
    this.cache = cache;
  }

  async getUserSettings(userId) {
    const cacheKey = `settings:${userId}`;
    
    // Try cache first
    const cached = await this.cache.get(cacheKey);
    if (cached) return JSON.parse(cached);
    
    // Fetch from database
    const settings = await this.db.settings.findOne({ userId });
    
    // Cache for future requests
    await this.cache.set(cacheKey, JSON.stringify(settings), 3600);
    
    return settings;
  }

  async updateSettings(userId, updates) {
    const settings = await this.db.settings.findOneAndUpdate(
      { userId },
      { $set: updates },
      { new: true, upsert: true }
    );

    // Update cache
    const cacheKey = `settings:${userId}`;
    await this.cache.set(cacheKey, JSON.stringify(settings), 3600);

    return settings;
  }

  async resetSettings(userId) {
    const defaultSettings = await this.getDefaultSettings();
    return this.updateSettings(userId, defaultSettings);
  }

  private async getDefaultSettings() {
    return {
      theme: 'light',
      notifications: {
        email: true,
        push: true,
        inApp: true
      },
      privacy: {
        profileVisibility: 'public',
        activityVisibility: 'connections'
      },
      language: 'en',
      timezone: 'UTC'
    };
  }
}
```

### 2. Settings Schema

```javascript
// backend/src/models/settings.js
const settingsSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  theme: {
    type: String,
    enum: ['light', 'dark', 'system'],
    default: 'system'
  },
  notifications: {
    email: {
      type: Boolean,
      default: true
    },
    push: {
      type: Boolean,
      default: true
    },
    inApp: {
      type: Boolean,
      default: true
    },
    types: {
      events: {
        type: Boolean,
        default: true
      },
      messages: {
        type: Boolean,
        default: true
      },
      updates: {
        type: Boolean,
        default: true
      }
    }
  },
  privacy: {
    profileVisibility: {
      type: String,
      enum: ['public', 'connections', 'private'],
      default: 'public'
    },
    activityVisibility: {
      type: String,
      enum: ['public', 'connections', 'private'],
      default: 'connections'
    },
    locationSharing: {
      type: Boolean,
      default: false
    }
  },
  language: {
    type: String,
    default: 'en'
  },
  timezone: {
    type: String,
    default: 'UTC'
  },
  accessibility: {
    fontSize: {
      type: String,
      enum: ['small', 'medium', 'large'],
      default: 'medium'
    },
    highContrast: {
      type: Boolean,
      default: false
    },
    reducedMotion: {
      type: Boolean,
      default: false
    }
  }
});
```

### 3. Settings Hook

```javascript
// frontend/src/hooks/useSettings.js
const useSettings = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  
  const {
    data: settings,
    isLoading,
    error
  } = useQuery(
    ['settings', user?.id],
    () => api.get(`/settings`).then(res => res.data),
    {
      enabled: !!user,
      staleTime: 300000, // 5 minutes
      cacheTime: 3600000 // 1 hour
    }
  );

  const updateSettingsMutation = useMutation(
    (updates) => api.patch('/settings', updates),
    {
      onSuccess: (data) => {
        queryClient.setQueryData(['settings', user?.id], data);
        applySettings(data);
      }
    }
  );

  const resetSettingsMutation = useMutation(
    () => api.post('/settings/reset'),
    {
      onSuccess: (data) => {
        queryClient.setQueryData(['settings', user?.id], data);
        applySettings(data);
      }
    }
  );

  // Apply settings to the application
  const applySettings = useCallback((settings) => {
    if (!settings) return;

    // Apply theme
    document.documentElement.setAttribute('data-theme', settings.theme);
    
    // Apply accessibility settings
    document.documentElement.style.fontSize = {
      small: '14px',
      medium: '16px',
      large: '18px'
    }[settings.accessibility.fontSize];

    if (settings.accessibility.highContrast) {
      document.documentElement.classList.add('high-contrast');
    } else {
      document.documentElement.classList.remove('high-contrast');
    }

    if (settings.accessibility.reducedMotion) {
      document.documentElement.classList.add('reduced-motion');
    } else {
      document.documentElement.classList.remove('reduced-motion');
    }
  }, []);

  // Apply settings on initial load
  useEffect(() => {
    if (settings) {
      applySettings(settings);
    }
  }, [settings, applySettings]);

  return {
    settings,
    isLoading,
    error,
    updateSettings: updateSettingsMutation.mutate,
    resetSettings: resetSettingsMutation.mutate
  };
};
```

### 4. Settings Components

```javascript
// frontend/src/components/settings/SettingsPanel.js
const SettingsPanel = () => {
  const { settings, updateSettings } = useSettings();
  const [localSettings, setLocalSettings] = useState(settings);

  const handleChange = (section, key, value) => {
    setLocalSettings(prev => ({
      ...prev,
      [section]: {
        ...prev[section],
        [key]: value
      }
    }));
  };

  const handleSave = () => {
    updateSettings(localSettings);
  };

  return (
    <div className="settings-panel">
      <ThemeSettings
        value={localSettings.theme}
        onChange={(value) => handleChange('theme', 'value', value)}
      />
      
      <NotificationSettings
        values={localSettings.notifications}
        onChange={(key, value) => handleChange('notifications', key, value)}
      />
      
      <PrivacySettings
        values={localSettings.privacy}
        onChange={(key, value) => handleChange('privacy', key, value)}
      />
      
      <AccessibilitySettings
        values={localSettings.accessibility}
        onChange={(key, value) => handleChange('accessibility', key, value)}
      />
      
      <Button onClick={handleSave}>Save Changes</Button>
    </div>
  );
};
```

## Remaining Implementation

### 1. Settings Sync

```javascript
// frontend/src/hooks/useSettingsSync.js
const useSettingsSync = () => {
  const { settings } = useSettings();
  const [syncStatus, setSyncStatus] = useState('idle');
  const [lastSynced, setLastSynced] = useState(null);

  const syncSettings = async () => {
    try {
      setSyncStatus('syncing');
      
      // Get local settings
      const localSettings = await localStorage.getItem('settings');
      
      // Get server settings
      const serverSettings = await api.get('/settings').then(res => res.data);
      
      // Merge settings with server taking precedence
      const mergedSettings = {
        ...JSON.parse(localSettings || '{}'),
        ...serverSettings
      };
      
      // Update local storage
      localStorage.setItem('settings', JSON.stringify(mergedSettings));
      
      // Update server
      await api.put('/settings', mergedSettings);
      
      setLastSynced(new Date());
      setSyncStatus('synced');
    } catch (error) {
      setSyncStatus('error');
      throw error;
    }
  };

  // Auto-sync on changes
  useEffect(() => {
    if (settings) {
      syncSettings();
    }
  }, [settings]);

  return {
    syncStatus,
    lastSynced,
    syncSettings
  };
};
```

### 2. Export/Import Settings

```javascript
// frontend/src/services/settingsExportService.js
class SettingsExportService {
  async exportSettings() {
    const settings = await api.get('/settings').then(res => res.data);
    
    const blob = new Blob(
      [JSON.stringify(settings, null, 2)],
      { type: 'application/json' }
    );
    
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `settings-${new Date().toISOString()}.json`;
    a.click();
    window.URL.revokeObjectURL(url);
  }

  async importSettings(file) {
    const text = await file.text();
    const settings = JSON.parse(text);
    
    // Validate settings
    await this.validateSettings(settings);
    
    // Update settings
    return api.put('/settings', settings);
  }

  private async validateSettings(settings) {
    const schema = yup.object().shape({
      theme: yup.string().oneOf(['light', 'dark', 'system']),
      notifications: yup.object(),
      privacy: yup.object(),
      accessibility: yup.object()
    });

    return schema.validate(settings);
  }
}
```

### 3. Settings Backup

```javascript
// backend/src/services/settingsBackupService.js
class SettingsBackupService {
  async createBackup(userId) {
    const settings = await this.settingsService.getUserSettings(userId);
    
    const backup = {
      userId,
      settings,
      createdAt: new Date(),
      version: '1.0'
    };

    await this.db.settingsBackups.create(backup);
    return backup;
  }

  async restoreBackup(userId, backupId) {
    const backup = await this.db.settingsBackups.findOne({
      _id: backupId,
      userId
    });

    if (!backup) {
      throw new Error('Backup not found');
    }

    return this.settingsService.updateSettings(userId, backup.settings);
  }

  async listBackups(userId) {
    return this.db.settingsBackups
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(10);
  }
}
```

## Implementation Timeline

### Week 1: Settings Sync
- Implement settings sync service
- Add conflict resolution
- Create sync status indicators
- Add automatic sync

### Week 2: Export/Import
- Create export functionality
- Add import validation
- Implement settings migration
- Add backup system

## Success Metrics
- Settings sync success rate > 99%
- Settings load time < 100ms
- Backup creation success rate > 99%
- Import validation success rate > 95%

## Settings Checklist
- [x] Basic settings management
- [x] Theme support
- [x] Notification preferences
- [x] Privacy settings
- [x] Accessibility options
- [ ] Settings sync
- [ ] Export/Import
- [ ] Settings backup
- [ ] Settings migration
- [ ] Conflict resolution
