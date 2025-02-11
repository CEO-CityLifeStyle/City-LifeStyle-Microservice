const validate = (schema) => {
  return (req, res, next) => {
    const validations = {};

    // Validate request body
    if (schema.body) {
      const { error } = schema.body.validate(req.body);
      if (error) {
        validations.body = error.details[0].message;
      }
    }

    // Validate query parameters
    if (schema.query) {
      const { error } = schema.query.validate(req.query);
      if (error) {
        validations.query = error.details[0].message;
      }
    }

    // Validate URL parameters
    if (schema.params) {
      const { error } = schema.params.validate(req.params);
      if (error) {
        validations.params = error.details[0].message;
      }
    }

    // If there are any validation errors
    if (Object.keys(validations).length > 0) {
      return res.status(400).json({
        error: Object.values(validations)[0] // Return the first error message
      });
    }

    next();
  };
};

module.exports = validate;
