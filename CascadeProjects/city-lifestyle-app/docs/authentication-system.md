# Authentication System Documentation

## Overview
The authentication system provides secure user authentication and authorization using JWT tokens, with support for multiple authentication methods and session management.

## Current Implementation

### 1. Core Authentication Service

```javascript
// backend/src/services/authService.js
class AuthenticationService {
  constructor(userService, tokenService) {
    this.userService = userService;
    this.tokenService = tokenService;
    this.refreshTokens = new Map();
  }

  async login(email, password) {
    const user = await this.userService.findByEmail(email);
    if (!user || !await bcrypt.compare(password, user.password)) {
      throw new AuthError('Invalid credentials');
    }

    return this.generateTokens(user);
  }

  async register(userData) {
    const existingUser = await this.userService.findByEmail(userData.email);
    if (existingUser) {
      throw new AuthError('Email already registered');
    }

    const hashedPassword = await bcrypt.hash(userData.password, 10);
    const user = await this.userService.create({
      ...userData,
      password: hashedPassword
    });

    return this.generateTokens(user);
  }

  async refreshToken(refreshToken) {
    const userId = this.tokenService.verifyRefreshToken(refreshToken);
    const storedToken = this.refreshTokens.get(userId);
    
    if (!storedToken || storedToken !== refreshToken) {
      throw new AuthError('Invalid refresh token');
    }

    const user = await this.userService.findById(userId);
    return this.generateTokens(user);
  }

  async logout(refreshToken) {
    const userId = this.tokenService.verifyRefreshToken(refreshToken);
    this.refreshTokens.delete(userId);
  }

  private async generateTokens(user) {
    const accessToken = this.tokenService.generateAccessToken(user);
    const refreshToken = this.tokenService.generateRefreshToken(user);
    
    this.refreshTokens.set(user.id, refreshToken);
    
    return {
      accessToken,
      refreshToken,
      user: this.userService.sanitizeUser(user)
    };
  }
}
```

### 2. Token Service

```javascript
// backend/src/services/tokenService.js
class TokenService {
  constructor(config) {
    this.config = config;
  }

  generateAccessToken(user) {
    return jwt.sign(
      { userId: user.id, role: user.role },
      this.config.jwt.accessSecret,
      { expiresIn: '15m' }
    );
  }

  generateRefreshToken(user) {
    return jwt.sign(
      { userId: user.id },
      this.config.jwt.refreshSecret,
      { expiresIn: '7d' }
    );
  }

  verifyAccessToken(token) {
    try {
      return jwt.verify(token, this.config.jwt.accessSecret);
    } catch (error) {
      throw new AuthError('Invalid access token');
    }
  }

  verifyRefreshToken(token) {
    try {
      const decoded = jwt.verify(token, this.config.jwt.refreshSecret);
      return decoded.userId;
    } catch (error) {
      throw new AuthError('Invalid refresh token');
    }
  }
}
```

### 3. Authentication Middleware

```javascript
// backend/src/middleware/auth.js
const authMiddleware = (tokenService) => async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AuthError('No token provided');
    }

    const token = authHeader.split(' ')[1];
    const decoded = tokenService.verifyAccessToken(token);
    
    req.user = decoded;
    next();
  } catch (error) {
    next(new AuthError('Authentication required'));
  }
};
```

### 4. Frontend Authentication Hook

```javascript
// frontend/src/hooks/useAuth.js
const useAuth = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const login = async (email, password) => {
    try {
      const response = await api.post('/auth/login', { email, password });
      const { accessToken, refreshToken, user } = response.data;
      
      localStorage.setItem('refreshToken', refreshToken);
      api.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
      
      setUser(user);
      return user;
    } catch (error) {
      setError(error.message);
      throw error;
    }
  };

  const register = async (userData) => {
    try {
      const response = await api.post('/auth/register', userData);
      const { accessToken, refreshToken, user } = response.data;
      
      localStorage.setItem('refreshToken', refreshToken);
      api.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
      
      setUser(user);
      return user;
    } catch (error) {
      setError(error.message);
      throw error;
    }
  };

  const logout = async () => {
    try {
      const refreshToken = localStorage.getItem('refreshToken');
      await api.post('/auth/logout', { refreshToken });
      
      localStorage.removeItem('refreshToken');
      delete api.defaults.headers.common['Authorization'];
      
      setUser(null);
    } catch (error) {
      setError(error.message);
      throw error;
    }
  };

  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) {
          setLoading(false);
          return;
        }

        const response = await api.post('/auth/refresh', { refreshToken });
        const { accessToken, user } = response.data;
        
        api.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
        setUser(user);
      } catch (error) {
        localStorage.removeItem('refreshToken');
        delete api.defaults.headers.common['Authorization'];
      } finally {
        setLoading(false);
      }
    };

    initializeAuth();
  }, []);

  return {
    user,
    loading,
    error,
    login,
    register,
    logout
  };
};
```

## Remaining Implementation

### 1. Enhanced Security Features

#### 1.1 Two-Factor Authentication
```javascript
// backend/src/services/twoFactorService.js
class TwoFactorService {
  async generateSecret(user) {
    const secret = speakeasy.generateSecret();
    await this.userService.update(user.id, {
      twoFactorSecret: secret.base32,
      twoFactorEnabled: false
    });
    return secret.otpauth_url;
  }

  async verifyAndEnable(user, token) {
    const isValid = speakeasy.totp.verify({
      secret: user.twoFactorSecret,
      encoding: 'base32',
      token
    });

    if (isValid) {
      await this.userService.update(user.id, {
        twoFactorEnabled: true
      });
    }

    return isValid;
  }

  async verify(user, token) {
    return speakeasy.totp.verify({
      secret: user.twoFactorSecret,
      encoding: 'base32',
      token
    });
  }
}
```

#### 1.2 Social Authentication
```javascript
// backend/src/services/socialAuthService.js
class SocialAuthService {
  async authenticateGoogle(token) {
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: this.config.google.clientId
    });
    
    const payload = ticket.getPayload();
    return this.findOrCreateUser({
      email: payload.email,
      name: payload.name,
      picture: payload.picture,
      provider: 'google'
    });
  }

  async authenticateFacebook(token) {
    const response = await fetch(`https://graph.facebook.com/me?fields=id,name,email,picture&access_token=${token}`);
    const data = await response.json();
    
    return this.findOrCreateUser({
      email: data.email,
      name: data.name,
      picture: data.picture.data.url,
      provider: 'facebook'
    });
  }

  private async findOrCreateUser(profile) {
    let user = await this.userService.findByEmail(profile.email);
    
    if (!user) {
      user = await this.userService.create({
        ...profile,
        password: null
      });
    }

    return this.authService.generateTokens(user);
  }
}
```

### 2. Security Enhancements

#### 2.1 Rate Limiting
```javascript
// backend/src/middleware/rateLimit.js
const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later'
});

const loginRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // limit each IP to 5 failed login attempts per hour
  skipSuccessfulRequests: true
});
```

#### 2.2 Enhanced Password Security
```javascript
// backend/src/services/passwordService.js
class PasswordService {
  async validatePassword(password) {
    const requirements = {
      minLength: 8,
      hasUpperCase: /[A-Z]/,
      hasLowerCase: /[a-z]/,
      hasNumbers: /\d/,
      hasSpecialChar: /[!@#$%^&*]/
    };

    const errors = [];
    
    if (password.length < requirements.minLength) {
      errors.push('Password must be at least 8 characters long');
    }
    if (!requirements.hasUpperCase.test(password)) {
      errors.push('Password must contain at least one uppercase letter');
    }
    if (!requirements.hasLowerCase.test(password)) {
      errors.push('Password must contain at least one lowercase letter');
    }
    if (!requirements.hasNumbers.test(password)) {
      errors.push('Password must contain at least one number');
    }
    if (!requirements.hasSpecialChar.test(password)) {
      errors.push('Password must contain at least one special character');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  async hashPassword(password) {
    return bcrypt.hash(password, 12);
  }
}
```

## Implementation Timeline

### Week 1: Security Enhancements
- Implement rate limiting
- Add enhanced password validation
- Set up security headers
- Add request validation

### Week 2: Two-Factor Authentication
- Implement 2FA service
- Add QR code generation
- Create verification flow
- Update login process

### Week 3: Social Authentication
- Set up Google OAuth
- Implement Facebook login
- Add profile merging
- Update user model

## Success Metrics
- Failed login attempt rate < 0.1%
- 2FA adoption rate > 30%
- Social auth usage > 40%
- Zero security incidents
- Password reset success rate > 95%

## Security Checklist
- [x] JWT implementation
- [x] Refresh token rotation
- [x] Password hashing
- [x] Basic rate limiting
- [ ] Two-factor authentication
- [ ] Social authentication
- [ ] Enhanced password validation
- [ ] Advanced rate limiting
- [ ] Security headers
- [ ] Request validation
