const Joi = require('joi');

const createReviewSchema = Joi.object({
  rating: Joi.number().min(1).max(5).required(),
  comment: Joi.string().required(),
  photos: Joi.array().items(Joi.string().uri())
});

const updateReviewSchema = Joi.object({
  rating: Joi.number().min(1).max(5),
  comment: Joi.string(),
  photos: Joi.array().items(Joi.string().uri())
});

module.exports = {
  createReviewSchema,
  updateReviewSchema
};
