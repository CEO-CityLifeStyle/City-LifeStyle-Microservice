module.exports = {
  Storage: jest.fn().mockImplementation(() => ({
    bucket: jest.fn().mockReturnValue({
      file: jest.fn().mockReturnValue({
        createWriteStream: jest.fn(),
        delete: jest.fn().mockResolvedValue([{}]),
        exists: jest.fn().mockResolvedValue([true])
      }),
      upload: jest.fn().mockResolvedValue([{}])
    })
  }))
};
