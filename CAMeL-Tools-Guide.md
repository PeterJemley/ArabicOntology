# CAMeL Tools — Installation and Usage Guide

A comprehensive guide to installing and using CAMeL Tools, an open-source Python toolkit for Arabic natural language processing developed by the CAMeL Lab at New York University Abu Dhabi.

---

## Overview

CAMeL Tools provides utilities for:
- Pre-processing Arabic text
- Morphological analysis and generation
- Dialect identification (25 city dialects + MSA)
- Named entity recognition
- Sentiment analysis

---

## Part 1: Prerequisites

### 1.1 System Requirements

| Requirement | Details |
|-------------|---------|
| Python | 3.8 – 3.12 (64-bit) |
| Rust compiler | Required for some dependencies |
| Operating System | Linux, macOS, Windows 10+ |

### 1.2 Install System Dependencies

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install cmake libboost-all-dev
```

**macOS:**
```bash
brew install cmake boost
```

**Windows:**
- CMake and Boost must be installed manually
- Note: Dialect Identification component is not available on Windows

---

## Part 2: Installation

### 2.1 Standard Installation (pip)

**Linux/macOS (Intel):**
```bash
pip install camel-tools
```

**macOS (Apple Silicon M1/M2/M3):**
```bash
CMAKE_OSX_ARCHITECTURES=arm64 pip install camel-tools
```

**Windows:**
```bash
pip install camel-tools -f https://download.pytorch.org/whl/torch_stable.html
```

### 2.2 Upgrade Existing Installation

**Linux/macOS (Intel):**
```bash
pip install camel-tools --upgrade
```

**macOS (Apple Silicon):**
```bash
CMAKE_OSX_ARCHITECTURES=arm64 pip install camel-tools --upgrade
```

**Windows:**
```bash
pip install --upgrade -f https://download.pytorch.org/whl/torch_stable.html camel-tools
```

### 2.3 Install from Source

```bash
# Clone the repo
git clone https://github.com/CAMeL-Lab/camel_tools.git
cd camel_tools

# Install from source
pip install .

# Or upgrade from source
pip install --upgrade .
```

---

## Part 3: Data Packages

CAMeL Tools requires data packages for its components to function.

### 3.1 Install Data Packages

```bash
# Install all datasets (recommended for full functionality)
camel_data -i all

# Or install lightweight package (morphology and MLE disambiguation only)
camel_data -i light

# Or install default datasets for each component
camel_data -i defaults
```

### 3.2 Data Storage Locations

| Platform | Default Location |
|----------|------------------|
| Linux/macOS | `~/.camel_tools` |
| Windows | `C:\Users\<username>\AppData\Roaming\camel_tools` |

### 3.3 Custom Data Location

To store data in a custom location, set the `CAMELTOOLS_DATA` environment variable.

**Linux/macOS:**
Add to your `.bashrc`, `.zshrc`, or `.profile`:
```bash
export CAMELTOOLS_DATA=/path/to/your/data
```

**Windows:**
1. Press Windows key and type "env"
2. Click "Edit the system environment variables"
3. Click "Environment Variables..."
4. Click "New..." under User variables
5. Variable name: `CAMELTOOLS_DATA`
6. Variable value: your desired path
7. Click OK

---

## Part 4: Command-Line Tools

CAMeL Tools provides several command-line utilities.

### 4.1 Available Commands

| Command | Description |
|---------|-------------|
| `camel_data` | Download and manage data packages |
| `camel_transliterate` | Transliterate between Arabic scripts |
| `camel_arclean` | Clean and normalize Arabic text |
| `camel_word_tokenize` | Tokenize Arabic text |
| `camel_dediac` | Remove diacritics from Arabic text |
| `camel_diac` | Add diacritics to Arabic text |
| `camel_morphology` | Morphological analysis/generation |

### 4.2 Morphology Command-Line Usage

**Analyze mode** (determine possible analyses for words):
```bash
echo "كتب" | camel_morphology analyze
```

**Generate mode** (generate inflections from lemma):
```bash
echo "كَتَبَ pos:verb" | camel_morphology generate
```

---

## Part 5: Python API

### 5.1 Morphological Analysis

```python
from camel_tools.morphology.database import MorphologyDB
from camel_tools.morphology.analyzer import Analyzer

# Load built-in database
# Flags: 'a' = analyze, 'g' = generate, 'r' = reinflect (both)
morph_db = MorphologyDB.builtin_db(flags='r')
analyzer = Analyzer(morph_db)

# Analyze a single word
analyses = analyzer.analyze('كتب')

# Analyze multiple words
words = ['كتب', 'الكتاب', 'يكتبون']
all_analyses = analyzer.analyze_words(words)
```

### 5.2 Morphological Generation

```python
from camel_tools.morphology.database import MorphologyDB
from camel_tools.morphology.generator import Generator

morph_db = MorphologyDB.builtin_db(flags='g')
generator = Generator(morph_db)

# Generate forms from lemma and features
forms = generator.generate('كَتَبَ', {'pos': 'verb', 'per': '3', 'gen': 'm'})
```

### 5.3 Dialect Identification

Identifies text among 25 Arabic city dialects plus MSA.

```python
from camel_tools.dialectid import DialectIdentifier

# Load pretrained model
did = DialectIdentifier.pretrained()

# Predict dialect for sentences
sentences = [
    'مال الهوى و مالي شكون اللي جابني ليك',  # Moroccan
    'بدي دوب قلي قلي بجنون بحبك انا مجنون'   # Levantine
]

predictions = did.predict(sentences)

# Get top prediction for each
for pred in predictions:
    print(f"Dialect: {pred.top}")
    print(f"Scores: {pred.scores}")
```

**Dialect Labels:**

| Label | City | Country | Region |
|-------|------|---------|--------|
| ALE | Aleppo | Syria | Levant |
| ALG | Algiers | Algeria | Maghreb |
| ALX | Alexandria | Egypt | Nile Basin |
| AMM | Amman | Jordan | Levant |
| ASW | Aswan | Egypt | Nile Basin |
| BAG | Baghdad | Iraq | Iraq |
| BAS | Basra | Iraq | Iraq |
| BEI | Beirut | Lebanon | Levant |
| BEN | Benghazi | Libya | Maghreb |
| CAI | Cairo | Egypt | Nile Basin |
| DAM | Damascus | Syria | Levant |
| DOH | Doha | Qatar | Gulf |
| FES | Fes | Morocco | Maghreb |
| JED | Jeddah | Saudi Arabia | Gulf |
| JER | Jerusalem | Palestine | Levant |
| KHA | Khartoum | Sudan | Nile Basin |
| MOS | Mosul | Iraq | Iraq |
| MSA | — | — | Standard |
| MUS | Muscat | Oman | Gulf |
| RAB | Rabat | Morocco | Maghreb |
| RIY | Riyadh | Saudi Arabia | Gulf |
| SAL | Salt | Jordan | Levant |
| SAN | Sana'a | Yemen | Gulf of Aden |
| SFX | Sfax | Tunisia | Maghreb |
| TRI | Tripoli | Libya | Maghreb |
| TUN | Tunis | Tunisia | Maghreb |

### 5.4 Text Preprocessing

```python
from camel_tools.utils.normalize import normalize_alef_maksura_ar
from camel_tools.utils.normalize import normalize_alef_ar
from camel_tools.utils.normalize import normalize_teh_marbuta_ar
from camel_tools.utils.dediac import dediac_ar

text = "الكِتَابُ"

# Remove diacritics
clean = dediac_ar(text)

# Normalize alef variants
normalized = normalize_alef_ar(text)
```

### 5.5 Tokenization

```python
from camel_tools.tokenizers.word import simple_word_tokenize

text = "هذا كتاب جميل"
tokens = simple_word_tokenize(text)
# ['هذا', 'كتاب', 'جميل']
```

### 5.6 Named Entity Recognition

```python
from camel_tools.ner import NERecognizer

ner = NERecognizer.pretrained()
sentence = "سافر محمد إلى القاهرة"

# Get NER labels
labels = ner.predict_sentence(sentence.split())
```

### 5.7 Sentiment Analysis

```python
from camel_tools.sentiment import SentimentAnalyzer

sa = SentimentAnalyzer.pretrained()
sentences = ["هذا الفيلم رائع", "الطعام سيء جدا"]

predictions = sa.predict(sentences)
# Returns: positive, negative, or neutral for each
```

---

## Part 6: Available Data Packages

| Package | Description |
|---------|-------------|
| `morphology-db-msa-*` | MSA morphology database |
| `morphology-db-egy-*` | Egyptian Arabic morphology |
| `morphology-db-glf-*` | Gulf Arabic morphology |
| `morphology-db-lev-*` | Levantine Arabic morphology |
| `disambig-mle-*` | MLE disambiguation models |
| `disambig-bert-*` | BERT-based disambiguation |
| `ner-*` | Named entity recognition models |
| `sentiment-*` | Sentiment analysis models |
| `dialectid-*` | Dialect identification models |

Use `camel_data -l` to list all available packages.

---

## Part 7: Building Documentation Locally

```bash
# Install documentation dependencies
pip install sphinx myst-parser sphinx-rtd-theme

# Go to docs subdirectory
cd docs

# Build HTML documentation
make html
```

Documentation will be compiled to `docs/build/html`.

---

## Part 8: Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError` | Ensure `pip install camel-tools` completed successfully |
| Data not found | Run `camel_data -i defaults` |
| Apple Silicon errors | Use `CMAKE_OSX_ARCHITECTURES=arm64` prefix |
| Windows dialect ID | Not supported on Windows |

### Verify Installation

```python
import camel_tools
print(camel_tools.__version__)
```

---

## Citation

When using CAMeL Tools in research, please cite:

```bibtex
@inproceedings{obeid-etal-2020-camel,
    title = "{CAM}e{L} Tools: An Open Source Python Toolkit for {A}rabic Natural Language Processing",
    author = "Obeid, Ossama and Zalmout, Nasser and Khalifa, Salam and Taji, Dima and Oudah, Mai and Alhafni, Bashar and Inoue, Go and Eryani, Fadhl and Erdmann, Alexander and Habash, Nizar",
    booktitle = "Proceedings of the Twelfth Language Resources and Evaluation Conference",
    year = "2020",
    address = "Marseille, France",
    publisher = "European Language Resources Association",
    pages = "7022--7032"
}
```

---

## Resources

- **GitHub:** https://github.com/CAMeL-Lab/camel_tools
- **Documentation:** https://camel-tools.readthedocs.io
- **PyPI:** https://pypi.org/project/camel-tools/
- **License:** MIT

---

*Document created: December 30, 2025*
