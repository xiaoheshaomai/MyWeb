/**
 * 腾讯云云函数：Morning60s 拍照验证后端
 * 接收 App 上传的图片（base64），用你的 Kimi API Key 调 Moonshot 识图，返回是否通过
 *
 * 环境变量（在 SCF 控制台配置）：
 *   MOONSHOT_API_KEY - 你的 Kimi API Key（从 platform.moonshot.cn 获取）
 */

const https = require('https');
const KIMI_HOST = 'api.moonshot.cn';
const KIMI_PATH = '/v1/chat/completions';
const VISION_MODEL = 'moonshot-v1-8k-vision-preview';
const PROMPT = '这张照片是否显示一个人从第一视角拍摄自己的脚，并站在地面上？只回答一个字：是 或 否。';

function postKimi(apiKey, payload) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(payload);
    const req = https.request({
      hostname: KIMI_HOST,
      path: KIMI_PATH,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body, 'utf8'),
        'Authorization': `Bearer ${apiKey}`
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data || '{}') });
        } catch (e) {
          resolve({ status: res.statusCode, data: {} });
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

exports.main_handler = async (event, context) => {
  const apiKey = process.env.MOONSHOT_API_KEY;
  if (!apiKey) {
    return resp(400, { passed: false, error: 'MOONSHOT_API_KEY not configured' });
  }

  let body;
  try {
    body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
  } catch (e) {
    return resp(400, { passed: false, error: 'Invalid JSON body' });
  }

  const imageBase64 = body.image;
  if (!imageBase64 || typeof imageBase64 !== 'string') {
    return resp(400, { passed: false, error: 'Missing field: image (base64 string)' });
  }

  const dataUrl = imageBase64.startsWith('data:') ? imageBase64 : `data:image/jpeg;base64,${imageBase64}`;

  const payload = {
    model: VISION_MODEL,
    messages: [
      {
        role: 'user',
        content: [
          { type: 'image_url', image_url: { url: dataUrl } },
          { type: 'text', text: PROMPT }
        ]
      }
    ],
    temperature: 0.1,
    max_completion_tokens: 16
  };

  try {
    const { status, data } = await postKimi(apiKey, payload);

    if (status !== 200) {
      const msg = data.error?.message || data.message || `HTTP ${status}`;
      return resp(200, { passed: false, error: msg });
    }

    const text = (data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content) ? data.choices[0].message.content.trim() : '';
    const passed = text.indexOf('是') === 0 || text.toUpperCase().indexOf('YES') !== -1;

    return resp(200, { passed });
  } catch (err) {
    return resp(200, { passed: false, error: err.message || 'Request failed' });
  }
};

function resp(statusCode, body) {
  return {
    isBase64Encoded: false,
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(body)
  };
}
