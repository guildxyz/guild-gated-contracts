module.exports = {
  env: {
    browser: false,
    es2021: true,
    mocha: true,
    node: true
  },
  plugins: ["@typescript-eslint"],
  extends: ["airbnb-base", "prettier", "plugin:node/recommended"],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    ecmaVersion: 12
  },
  rules: {
    "func-names": "off",
    "no-console": "off",
    "import/no-extraneous-dependencies": ["error", { devDependencies: true }],
    "node/no-unpublished-import": "off",
    "node/no-unsupported-features/es-syntax": ["error", { ignores: ["modules"] }]
  }
};
