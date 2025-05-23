module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
  ],
  rules: {
    quotes: ["error", "double"],
    "max-len": ["error", { "code": 100 }],
    "no-console": "off", // Allow console.log for Firebase Functions
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "indent": ["error", 2],
    "semi": ["error", "always"],
    "comma-dangle": ["error", "always-multiline"],
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
}; 