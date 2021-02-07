declare namespace NodeJS {
  interface ProcessEnv {
    FORKING_URL: string
    NODE_ENV: 'development' | 'production'
  }
}