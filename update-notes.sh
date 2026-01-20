#!/bin/bash

# Script to update lecture notes from the crypto-berkeley/276 repository
# This script:
# 1. Clones/pulls the notes repository
# 2. Compiles notes.tex
# 3. Copies the compiled PDF to assets/lecture-notes/notes.pdf
# 4. Commits and pushes the changes

# Don't exit on error for individual commands, we'll handle errors explicitly

REPO_URL="https://github.com/crypto-berkeley/276.git"
REPO_DIR="/tmp/276-notes"
NOTES_TEX="notes.tex"
TARGET_PDF="assets/lecture-notes/notes.pdf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating lecture notes..."

# Step 1: Clone or update the repository
if [ -d "$REPO_DIR" ]; then
    echo "Repository exists, pulling latest changes..."
    cd "$REPO_DIR"
    git pull
    # Update submodules if they exist
    if [ -f ".gitmodules" ]; then
        echo "Updating submodules..."
        git submodule update --init --recursive
    fi
else
    echo "Cloning repository..."
    git clone --recursive "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Step 2: Compile notes.tex
echo "Compiling notes.tex..."
if ! command -v pdflatex &> /dev/null; then
    echo "Error: pdflatex is not installed. Please install a LaTeX distribution."
    exit 1
fi

# Run pdflatex multiple times to resolve references and cross-references
# First pass
echo "Running pdflatex (pass 1)..."
pdflatex -interaction=nonstopmode "$NOTES_TEX" > /tmp/notes-compile.log 2>&1 || true

# Run bibtex if .bib file exists
if [ -f "notes.bib" ] || ls *.bib 2>/dev/null | grep -q .; then
    echo "Running bibtex..."
    bibtex notes > /tmp/notes-bibtex.log 2>&1 || true
    # Run pdflatex again after bibtex
    echo "Running pdflatex (pass 2, after bibtex)..."
    pdflatex -interaction=nonstopmode "$NOTES_TEX" > /tmp/notes-compile.log 2>&1 || true
fi

# Final pass to resolve all references
echo "Running pdflatex (final pass)..."
pdflatex -interaction=nonstopmode "$NOTES_TEX" > /tmp/notes-compile.log 2>&1 || true

# Check if PDF was created
if [ ! -f "notes.pdf" ]; then
    echo "Error: Failed to compile notes.tex. PDF not found."
    echo "Check /tmp/notes-compile.log for compilation errors."
    exit 1
fi

echo "Compilation successful."

# Step 3: Copy PDF to assets/lecture-notes/notes.pdf
echo "Copying PDF to assets/lecture-notes/notes.pdf..."
cd "$SCRIPT_DIR"
cp "$REPO_DIR/notes.pdf" "$TARGET_PDF"

# Step 4: Git commit and push
echo "Committing and pushing changes..."
git add "$TARGET_PDF"
git commit -m "Update lecture notes from crypto-berkeley/276 repository" || echo "No changes to commit"
git push || echo "Push failed or no remote configured"

echo "Done! Lecture notes updated."
