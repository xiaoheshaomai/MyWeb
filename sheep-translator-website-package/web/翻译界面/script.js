const MODEL_URL = 'https://teachablemachine.withgoogle.com/models/xtenQdqej/';
const DICTIONARY_KEY = 'sheepTranslatorSequenceDictionary';
const BACKGROUND_LABEL = 'Background Noise';
const CONFIDENCE_THRESHOLD = 0.74;
const ACCEPT_COOLDOWN_MS = 850;

const startScreen = document.querySelector('[data-screen="start"]');
const resultScreen = document.querySelector('[data-screen="result"]');
const startButton = document.querySelector('.start-button');
const listenStatus = document.querySelector('.listen-status');
const resultText = document.querySelector('.result-text');
const resultClass = document.querySelector('.result-class');
const prettyResultButton = document.querySelector('.pretty-result-button');
const prettyResultWord = document.querySelector('.pretty-result-word');
const sheepFront = document.querySelector('.sheep-front');

let recognizer;
let isListening = false;
let lastAcceptedAt = 0;
let sequence = [];

function loadDictionary() {
  try {
    return JSON.parse(localStorage.getItem(DICTIONARY_KEY)) || {};
  } catch {
    return {};
  }
}

async function createModel() {
  if (recognizer) {
    return recognizer;
  }

  recognizer = speechCommands.create(
    'BROWSER_FFT',
    undefined,
    `${MODEL_URL}model.json`,
    `${MODEL_URL}metadata.json`
  );

  await recognizer.ensureModelLoaded();
  return recognizer;
}

function sequenceKey(tokens = sequence) {
  return tokens.join(' ');
}

function bestPrediction(scores, labels) {
  return labels
    .map((label, index) => ({ label, score: scores[index] }))
    .filter((prediction) => prediction.label !== BACKGROUND_LABEL)
    .sort((a, b) => b.score - a.score)[0];
}

function dictionaryKeys() {
  return Object.keys(loadDictionary()).filter(Boolean);
}

function isPrefix(tokens, key) {
  const keyTokens = key.split(' ');

  if (tokens.length > keyTokens.length) {
    return false;
  }

  return tokens.every((token, index) => token === keyTokens[index]);
}

function trimToKnownPrefix(tokens) {
  const keys = dictionaryKeys();

  for (let start = 0; start < tokens.length; start += 1) {
    const candidate = tokens.slice(start);

    if (keys.some((key) => isPrefix(candidate, key))) {
      return candidate;
    }
  }

  return [];
}

function showResult(key, score) {
  const dictionary = loadDictionary();

  resultText.textContent = dictionary[key];
  resultClass.textContent = '';
  startScreen.classList.remove('is-active');
  resultScreen.classList.add('is-active');
}

function hidePrettyResult() {
  prettyResultWord.classList.remove('is-visible');
  prettyResultWord.setAttribute('aria-hidden', 'true');
}

function showPrettyResult() {
  prettyResultWord.classList.add('is-visible');
  prettyResultWord.setAttribute('aria-hidden', 'false');
}

async function stopListening() {
  if (!recognizer || !isListening) {
    return;
  }

  await recognizer.stopListening();
  isListening = false;
}

async function handlePrediction(prediction) {
  const now = Date.now();

  if (!prediction || prediction.score < CONFIDENCE_THRESHOLD || now - lastAcceptedAt < ACCEPT_COOLDOWN_MS) {
    return;
  }

  lastAcceptedAt = now;
  sequence = trimToKnownPrefix([...sequence, prediction.label]);

  const key = sequenceKey();
  const dictionary = loadDictionary();
  listenStatus.textContent = key || prediction.label;

  if (key && dictionary[key]) {
    await stopListening();
    showResult(key, prediction.score);
  }
}

async function startListening() {
  if (isListening) {
    return;
  }

  if (!window.speechCommands) {
    listenStatus.textContent = 'Model library did not load.';
    return;
  }

  if (dictionaryKeys().length === 0) {
    listenStatus.textContent = 'Save a baa sequence first.';
    return;
  }

  startButton.disabled = true;
  startButton.textContent = 'LOADING...';
  listenStatus.textContent = 'Preparing microphone';

  try {
    const model = await createModel();
    const labels = model.wordLabels();

    isListening = true;
    sequence = [];
    lastAcceptedAt = 0;
    hidePrettyResult();
    startButton.textContent = 'LISTENING...';
    listenStatus.textContent = 'Baa now';

    model.listen(
      (result) => {
        handlePrediction(bestPrediction(result.scores, labels));
      },
      {
        includeSpectrogram: true,
        invokeCallbackOnNoiseAndUnknown: true,
        overlapFactor: 0.5,
        probabilityThreshold: 0.35
      }
    );
  } catch (error) {
    startButton.disabled = false;
    startButton.textContent = 'START TO BAA~';
    listenStatus.textContent = 'Microphone or model failed.';
    console.error(error);
  }
}

startButton.addEventListener('click', startListening);
prettyResultButton.addEventListener('click', showPrettyResult);

sheepFront.addEventListener('click', () => {
  resultScreen.classList.remove('is-active');
  startScreen.classList.add('is-active');
  startButton.disabled = false;
  startButton.textContent = 'START TO BAA~';
  listenStatus.textContent = '';
  sequence = [];
  hidePrettyResult();
});
