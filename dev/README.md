# Workspace scripts

These assume the layout they were written against:

```
LeoServ/
  betterSkillys/        <- this repo
    dev/                <- these scripts
  tools/flexsdk/        <- Apache Flex SDK 4.16.1 (not in the repo)
  tools/playerglobal32_0.swc
  tools/build-config.xml
```

The paths inside the .bat files are relative to `LeoServ/`, so run them from
there rather than from `dev/`. The Flex SDK is deliberately not committed - it
is a 130MB third-party download. See the client build notes below to recreate
`tools/`.

## Rebuilding the client toolchain

The client is ActionScript 3 and needs a compiler. Adobe's AIR SDK links are
dead and HARMAN's require an account, so this uses Apache Flex instead:

- `apache-flex-sdk-4.16.1-bin.zip` from archive.apache.org -> `tools/flexsdk`
- `playerglobal32_0.swc` from fpdownload.macromedia.com -> `tools/`
- `afe.jar`, `aglj40.jar`, `flex-fontkit.jar`, `rideau.jar` from the SourceForge
  URLs listed in the SDK's own `installer.xml` -> `tools/flexsdk/lib/external/optional/`
  (the Myriad Pro OTF embeds will not transcode without these)

`build-config.xml` sets the font managers, putting JREFontManager ahead of
Batik, which cannot parse OTF/CFF outlines.
