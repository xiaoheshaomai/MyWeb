const MODEL_URL = 'https://teachablemachine.withgoogle.com/models/xtenQdqej/';
const DICTIONARY_KEY = 'sheepTranslatorSequenceDictionary';
const BACKGROUND_LABEL = 'Background Noise';
const CONFIDENCE_THRESHOLD = 0.74;
const ACCEPT_COOLDOWN_MS = 850;

const composeScreen = document.querySelector('[data-screen="compose"]');
const recordScreen = document.querySelector('[data-screen="record"]');
const doneScreen = document.querySelector('[data-screen="done"]');
const composeSheepButton = document.querySelector('.compose-sheep-button');
const messageForm = document.querySelector('.message-form');
const messageInput = document.querySelector('.message-input');
const submitButton = document.querySelector('.submit-button');
const recordButton = document.querySelector('.record-button');
const sequenceList = document.querySelector('.sequence-list');
const saveStatus = document.querySelector('.save-status');
const savedLabel = document.querySelector('.saved-label');
const doneSummary = document.querySelector('.done-summary');

let recognizer;
let isListening = false;
let lastAcceptedAt = 0;
let sequence = [];
let pendingMessage = '';

function loadDictionary() {
  try {
    return JSON.parse(localStorage.getItem(DICTIONARY_KEY)) || {};
  } catch {
    return {};
  }
}

function saveDictionary(dictionary) {
  localStorage.setItem(DICTIONARY_KEY, JSON.stringify(dictionary));
}

function sequenceKey(tokens = sequence) {
  return tokens.join(' ');
}

function renderSequence() {
  sequenceList.innerHTML = '';

  sequence.forEach((label) => {
    const chip = document.createElement('span');
    chip.className = 'sequence-chip';
    chip.textContent = label;
    sequenceList.append(chip);
  });
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

function bestPrediction(scores, labels) {
  return labels
    .map((label, index) => ({ label, score: scores[index] }))
    .filter((prediction) => prediction.label !== BACKGROUND_LABEL)
    .sort((a, b) => b.score - a.score)[0];
}

function acceptPrediction(prediction) {
  const now = Date.now();

  if (!prediction || prediction.score < CONFIDENCE_THRESHOLD || now - lastAcceptedAt < ACCEPT_COOLDOWN_MS) {
    return;
  }

  lastAcceptedAt = now;
  sequence.push(prediction.label);
  saveStatus.textContent = `Recorded: ${sequenceKey()}`;
  renderSequence();
}

async function saveCurrentSequence() {
  if (pendingMessage.length === 0 || sequence.length === 0) {
    saveStatus.textContent = 'Press mic to record baa.';
    return false;
  }

  const key = sequenceKey();
  const dictionary = loadDictionary();
  dictionary[key] = pendingMessage;
  saveDictionary(dictionary);
  saveStatus.textContent = `Saved: ${key} = ${pendingMessage}`;
  savedLabel.textContent = `Saved: ${key} = ${pendingMessage}`;
  doneSummary.textContent = `${key} = ${pendingMessage}`;
  return true;
}

async function stopSequenceListening() {
  if (!recognizer || !isListening) {
    return;
  }

  await recognizer.stopListening();
  isListening = false;
  recordButton.classList.remove('is-recording');
  recordButton.setAttribute('aria-label', 'Start recording');
  const didSave = await saveCurrentSequence();

  if (didSave) {
    showScreen('done');
  }
}

async function startSequenceListening() {
  if (isListening) {
    await stopSequenceListening();
    return;
  }

  if (!window.speechCommands) {
    saveStatus.textContent = 'Model library did not load.';
    return;
  }

  saveStatus.textContent = 'Preparing microphone';

  try {
    const model = await createModel();
    const labels = model.wordLabels();

    isListening = true;
    lastAcceptedAt = 0;
    recordButton.classList.add('is-recording');
    recordButton.setAttribute('aria-label', 'Stop recording');
    saveStatus.textContent = 'Listening...';

    model.listen(
      (result) => {
        acceptPrediction(bestPrediction(result.scores, labels));
      },
      {
        includeSpectrogram: true,
        invokeCallbackOnNoiseAndUnknown: true,
        overlapFactor: 0.5,
        probabilityThreshold: 0.35
      }
    );
  } catch (error) {
    isListening = false;
    recordButton.classList.remove('is-recording');
    recordButton.setAttribute('aria-label', 'Start recording');
    saveStatus.textContent = 'Microphone or model failed.';
    console.error(error);
  }
}

function showScreen(name) {
  composeScreen.classList.toggle('is-active', name === 'compose');
  recordScreen.classList.toggle('is-active', name === 'record');
  doneScreen.classList.toggle('is-active', name === 'done');
}

function showMessageInput() {
  messageForm.classList.add('is-visible');
  messageInput.focus();
}

function updateSubmitState() {
  submitButton.disabled = messageInput.value.trim().length === 0;
}

composeSheepButton.addEventListener('click', showMessageInput);

messageInput.addEventListener('input', updateSubmitState);

messageForm.addEventListener('submit', (event) => {
  event.preventDefault();

  pendingMessage = messageInput.value.trim();

  if (pendingMessage.length === 0) {
    showMessageInput();
    return;
  }

  sequence = [];
  renderSequence();
  saveStatus.textContent = 'Press mic to record baa.';
  savedLabel.textContent = `Record baa for "${pendingMessage}"`;
  messageInput.blur();
  showScreen('record');
});

recordButton.addEventListener('click', startSequenceListening);

renderSequence();
updateSubmitState();
