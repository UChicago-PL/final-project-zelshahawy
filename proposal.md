# Final Project Proposal for CMSC 22300
# Project Title: PolyCodec: A Multi-Purpose, Multi-Media OS-Agnostic Encoder/Decoder

## Author: Ziad Elshahawy
## Email: zelshahawy@uchicago.edu

### Concept Overview

For my final project, I considered several ideas, including an image processor, a C++-like algorithms library, and a RAG-based system. After deliberation, I decided to focus on a more systems-oriented project: a multi-purpose encoder and decoder application.
The application will provide a general framework for encoding and decoding files using different compression algorithms. Users will be able to choose which algorithm to apply, while the program reports information such as expected or actual compression size
to help guide that choice. The emphasis of the project is on correctness, performance, and clean system design rather than on compression alone.

### Goals and Milestones
#### Easy

- Implement at least one lossless compression algorithm (namely LZW or Huffman).

- Support encoding and decoding of files via a command-line interface.

- Ensure decoded output exactly matches the original input.

- Reduce unnecessary I/O using a relatively lazy, streaming-based approach.

#### Medium

- Support multiple compression algorithms.

- Report compression ratios and output sizes.

- Add multithreading to process multiple files concurrently.

- Design the system to be easily extensible with new algorithms.

#### Challenge

- Use multithreading to compress a single file in parallel.

- Experiment with or partially implement a lossy audio compression algorithm (e.g., MP3-style), time permitting.

- Further optimize performance for large inputs.

- Depending on progress, the project may remain focused on efficient lossless compression or expand into a broader comparison framework for different heuristics.

### Additional Topics and Resources

This project will require learning more about compression algorithms, multithreading, and efficient file I/O. I expect to learn most of these independently through documentation and reference implementations, though concurrency design and performance tradeoffs may
benefit from discussion in office hours or class.

### Inspiration and Collaboration

This idea is inspired by course assigment such as the vigenere assigment, prior systems programming experience, and personal interest in performance-critical software. I plan to discuss ideas with classmates and TA's, giving the appropriate citations when needed.
