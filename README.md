# DaSiWa MiniMax H3 (picture to video with sound) — RunPod Serverless worker

A ready-to-build [RunPod Serverless](https://runpod.io?ref=qpguwapm) worker for **[DaSiWa MiniMax H3 — Hybrid v4 Turbo](https://civitai.com/models/2877206?modelVersionId=3392061)** by [Darksidewalker](https://civitai.com/user/Darksidewalker), a MiniMax H3 fine-tune that makes video with its own sound (voice, effects, music) from your picture (8 steps). Based on the official [`runpod/worker-comfyui`](https://github.com/runpod-workers/worker-comfyui).

Models are baked into the image, so a cold start does not re-download anything.

> You download it with your own Civitai account and are responsible for following the model licenses ([MiniMax H3 Community License](https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/LICENSE)).

## What's inside

| File | Source | Size |
|---|---|---|
| `diffusion_models/dasiwa_minimax_h3_v4_turbo_int8.safetensors` | [Civitai 2877206 / version 3392061](https://civitai.com/models/2877206?modelVersionId=3392061) | 20.5 GB |
| `text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` | [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3) | 15.7 GB |
| `vae/minimax_h3_video_vae_int8_convrot.safetensors` | [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3) | 2.8 GB |
| `vae/minimax_h3_audio_vae_fp32.safetensors` | [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3) | 0.6 GB |

Just the model as its creator released it — no LoRAs, no extra nodes. All files are checked by SHA-256 at build time. ComfyUI is upgraded to 0.43.1 (MiniMax H3 is built into ComfyUI from there on).

## Setup (about 10 minutes + build time)

New to this? Follow the [step-by-step setup guide](https://cobaltpear.github.io/guide.html).

1. **Make your own private copy** — click **Use this template** → **Create a new repository** → choose **Private**.
   (Your Civitai token will be in it, so it must stay private.)
2. **Add your Civitai token** — get one at civitai.com → Account settings → **Security & Apps** → **API Keys** → **Add API key** → Permission preset **Read Only**.
   In your copy, open `Dockerfile` → ✏️ edit → replace `PASTE_YOUR_CIVITAI_TOKEN_HERE` on line 6 → Commit.
   No RunPod account yet? [Sign up here](https://runpod.io?ref=qpguwapm) — a referral link: after you first add $10, RunPod gives you a bonus credit (usually $5–10) and this repo a small credit.
3. **Create the endpoint** — see [Create the endpoint](#create-the-endpoint) below.
4. **Create an API key** — RunPod → Settings → API Keys → **Restricted**, allow only this endpoint.

## Create the endpoint

RunPod → **Serverless** → **New Endpoint** → **Deploy from a GitHub repository** → pick your copy (the first time, **Edit connection** lets RunPod see it). Then, top to bottom on the page:

| Where on the page | What to set |
|---|---|
| **Endpoint name** | anything — your copy's name is fine |
| **GPU configuration** | tick a box of 48 GB or more (more boxes = easier to get a GPU) |
| **Max workers** | `1` |
| Click **Advanced settings** to open it: | |
| → **Active workers** | `0` — nothing to pay while idle |
| → **GPU count** | `1` |
| → **Idle timeout** | `5` sec — or longer if you make several in a row (see below) |
| → **Enable FlashBoot** | on (the switch) · **Standard** |
| → **Enable execution timeout** | on · **Execution timeout** `900` sec |
| → click **Container configuration** to open it → **Container disk** | 80 GB |

Leave everything else as it is, then **Deploy** at the bottom. The first build takes a while (it downloads about 40 GB).
<!-- cp:initializing first=request -->
The very first request after that waits while a worker pulls the image — this can take a long time. The worker shows **Initializing**. To see what it's doing: endpoint page → **Workers** → click the worker → **Logs** → **System**.

- No error → leave it. A big image can sit on one line for a long time. Lines starting with `INFO` are normal.
- The same error keeps repeating → delete that worker with the 🗑 icon at the right end of its row. RunPod starts a new one.
- Still failing after that → ask us in [Discussions](https://github.com/cobaltpear/cobaltpear.github.io/discussions) with a screenshot of the log, or the whole log.
<!-- /cp:initializing -->

**Making several in a row?**

<!-- cp:several result=result -->
RunPod turns the worker off 5 seconds after each result (**Idle timeout** `5` sec). The next request then waits while a worker starts and loads the model again. It may be the same machine or a different one, so this wait can be short or long.

If you look at a result and send the next one soon after, set **Idle timeout** higher, for example `300` sec (endpoint page → **Manage** → **Edit Endpoint** → **Advanced settings**). The worker then stays on for that long after each result, and the next one starts right away. You pay for that time too, so set it back to `5` when you're done.

In short: `5` sec means you wait at each start and pay nothing while idle. Longer means no wait, and you pay while it waits for you.
<!-- /cp:several -->

## Or run it on Modal

The same worker also runs on [Modal](https://modal.com) — another serverless GPU service, billed by the second — from `modal_app.py` in this repo. It builds the same `Dockerfile` and answers the same requests as on RunPod (`/run`, `/status/<id>`), so a client that calls RunPod endpoints needs only the other address and key.

On your computer, with Python 3.10 or newer, in a copy of your repo (`git clone` it, with your `Dockerfile` lines filled in):

```sh
pip install modal
modal setup                                                   # opens a page to sign in to Modal
modal secret create cobaltpear-key CP_KEY=<a long password you make up>
modal deploy modal_app.py                                     # builds, then prints the worker's address
```

- The address ending in `-api….modal.run` is your endpoint; send `Authorization: Bearer <that password>` with each request.
- GPU: the `GPU` line at the top of `modal_app.py` (48 GB by default). A worker turns off 60 s after its last picture.
- Modal needs a payment method on your account to use GPUs. Its prices: [modal.com/pricing](https://modal.com/pricing).
- Updates: run `modal deploy modal_app.py` again.

## Updates

Your copy only holds the token. The build steps (`build.sh`, `handler.py`) are downloaded from this repo on every build, so when something changes upstream (a model file is replaced, ComfyUI needs an update) it is fixed here — you just rebuild your endpoint.

To rebuild: commit any change to the `main` branch of your copy — RunPod builds again on every push to `main` (the endpoint's **Builds** tab shows it). Nothing to change? Edit `README.md` (✏️), add a line, **Commit changes…** → **Commit changes**.

### Model version

This repo always follows the version the model's creator currently recommends. Now: **Hybrid v4 Turbo, Civitai version 3392061 (int8)**.
Each change of the build files is kept as a release (`files-…`). To stay on one, replace `latest/download` with `download/files-…` (that release's name) in both `ADD` lines of your `Dockerfile`.

## Use it

Any client that sends ComfyUI API-format workflows to RunPod works. `pack.json` in this repo holds the workflow and tells a client where the prompt, seed and size go (format `pack/1`, engine `comfyui`).

Raw request:

```bash
IMG=$(base64 -w0 photo.png)
curl -X POST https://api.runpod.ai/v2/<ENDPOINT_ID>/runsync \
  -H "Authorization: Bearer <API_KEY>" -H "Content-Type: application/json" \
  -d "{\"input\": {\"workflow\": $(jq .workflow pack.json | jq '.["6"].inputs.string_b = "She turns her head and smiles. Soft room tone, a quiet laugh." | .["15"].inputs.noise_seed = 1'), \"images\": [{\"name\": \"start_image.png\", \"image\": \"$IMG\"}]}}"
```

Your picture goes in `images` under the name `start_image.png` — the workflow's LoadImage node reads it from there.

The video (MP4 with sound) comes back as base64 in `output.images[0].data`.

Tips: Starts from your picture: 5 s at 24 fps with sound, 8 steps. Describe the motion and the sound, not the picture. The worker puts one line in front of your prompt that tells H3 to start from your picture (the creator's own wording); for longer prompts, see the creator's [prompting guide](https://github.com/darksidewalker/ComfyUI-DaSiWa-Nodes/blob/main/docs/minimax_h3_director.md).

### LoRAs

- **Per picture:** send up to 4 LoRAs with a request: `input.remote_loras` = `[{"name": "remote_<id>.safetensors", "url": "<download link>", "sha256": "<file sha256>"}]` plus a `LoraLoader` reading that name in the workflow — the worker downloads each once and keeps it while it runs. [Cobalt Pear](https://cobaltpear.github.io/) does all of this from a Civitai or Hugging Face link. For more than 4, set the environment variable `REMOTE_LORA_MAX` (e.g. `8`) on your endpoint (**Manage → Edit Endpoint → Environment Variables**).
- **Built in:** put links in the `LORAS` line of your `Dockerfile` — each followed by its strength — and rebuild. They are downloaded once at build time, so a fresh worker doesn't download them again. A request picks which ones it uses with `input.baked_loras` = `[{"link": "<link from LORAS>", "strength": 0.8}]` (`[]` = none); without it every one is used at its `LORAS` strength. One that isn't built in (yet) is left out and named in `output.warning`, and `output.built_in` lists the built-in LoRAs. Put their trigger words in your prompt yourself. To accept only built-in LoRAs, set `REMOTE_LORA_MAX` to `0`.
<!-- cp:video-loras -->
- **Video model:** the worker is big, so its build is already long. Built-in LoRAs add to it, and RunPod stops a build after 30 minutes — so for this model, send LoRAs with each request (**By link** in Cobalt Pear).
<!-- /cp:video-loras -->
- Pick LoRAs made for this model's base model — the worker warns (`output.warning`) when one doesn't fit.

### Compatible clients

- [Cobalt Pear](https://cobaltpear.github.io/) — a one-page web app: add this repo's URL, your endpoint ID and API key, then attach a picture and type the motion. Everything stays in your browser. [Try the demo](https://cobaltpear.github.io/demo/) without RunPod.

<!-- cp:page-changes -->
RunPod and Civitai change their pages from time to time. If a button or step here looks different from what you see, tell us in [Discussions](https://github.com/cobaltpear/cobaltpear.github.io/discussions) and we'll update this guide.
<!-- /cp:page-changes -->

Questions or ideas: [Discussions](https://github.com/cobaltpear/cobaltpear.github.io/discussions).

## License

AGPL-3.0 ([LICENSE](LICENSE)). This worker is based on [runpod-workers/worker-comfyui](https://github.com/runpod-workers/worker-comfyui) (AGPL-3.0), and `handler.py` is a changed copy of its handler. The models you build into it keep their own licenses.
