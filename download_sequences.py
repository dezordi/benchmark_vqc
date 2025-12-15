import argparse
import time
import sys
from Bio import Entrez
from urllib.error import HTTPError
import http.client

def download_sequences(input_file, output_file, email, api_key):
    Entrez.email = email
    Entrez.api_key = api_key
    
    try:
        with open(input_file, 'r') as f:
            accessions = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)

    total_ids = len(accessions)
    print(f"Found {total_ids} accessions to download.")
    
    # NCBI recommends: with API key = 10 requests/sec, without = 3 requests/sec
    # To be safe with large downloads, we use small batches and add delays
    
    chunk_size = 500  # Smaller chunks for epost to avoid history issues
    retmax = 200      # Smaller efetch batches to avoid 400/504 errors
    delay_between_fetches = 0.15  # 150ms delay between efetch calls (safe for API key)
    
    with open(output_file, 'w') as out_f:
        for i in range(0, total_ids, chunk_size):
            chunk = accessions[i:i + chunk_size]
            chunk_num = i // chunk_size + 1
            total_chunks = (total_ids + chunk_size - 1) // chunk_size
            print(f"Processing chunk {chunk_num}/{total_chunks} ({len(chunk)} IDs)...")
            
            # Post IDs to history server
            attempt = 0
            max_attempts = 5
            webenv = None
            query_key = None
            
            while attempt < max_attempts:
                try:
                    search_handle = Entrez.epost(db="nucleotide", id=",".join(chunk))
                    search_results = Entrez.read(search_handle)
                    search_handle.close()
                    webenv = search_results["WebEnv"]
                    query_key = search_results["QueryKey"]
                    break
                except Exception as e:
                    attempt += 1
                    print(f"  Error posting to history: {e}. Retrying ({attempt}/{max_attempts})...")
                    time.sleep(2 * attempt)
            
            if webenv is None:
                print(f"  Failed to post chunk {chunk_num}. Skipping...")
                continue

            # Fetch sequences using history
            count = len(chunk)
            for start in range(0, count, retmax):
                fetch_attempt = 0
                while fetch_attempt < max_attempts:
                    try:
                        fetch_handle = Entrez.efetch(
                            db="nucleotide",
                            rettype="fasta",
                            retmode="text",
                            retstart=start,
                            retmax=retmax,
                            webenv=webenv,
                            query_key=query_key
                        )
                        data = fetch_handle.read()
                        fetch_handle.close()
                        out_f.write(data)
                        out_f.flush()  # Ensure data is written immediately
                        time.sleep(delay_between_fetches)  # Rate limiting delay
                        break
                    except (HTTPError, http.client.IncompleteRead) as e:
                        fetch_attempt += 1
                        wait_time = 2 ** fetch_attempt  # Exponential backoff
                        print(f"  Error fetching {start}-{start+retmax}: {e}. Waiting {wait_time}s... ({fetch_attempt}/{max_attempts})")
                        time.sleep(wait_time)
                    except Exception as e:
                        fetch_attempt += 1
                        wait_time = 2 ** fetch_attempt
                        print(f"  Unexpected error: {e}. Waiting {wait_time}s... ({fetch_attempt}/{max_attempts})")
                        time.sleep(wait_time)
                
                if fetch_attempt == max_attempts:
                    print(f"  Failed batch {start}-{start+retmax}. Some sequences may be missing.")
            
            # Small delay between chunks
            time.sleep(0.5)

    print(f"Download complete. Sequences saved to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download sequences from NCBI based on accession IDs.")
    parser.add_argument("-i", "--input", required=True, help="Input file containing one Accession ID per line.")
    parser.add_argument("-o", "--output", required=True, help="Output FASTA file.")
    parser.add_argument("--email", required=True, help="Email address for NCBI services.")
    parser.add_argument("--api-key", required=True, help="NCBI API Key.")

    args = parser.parse_args()
    download_sequences(args.input, args.output, args.email, getattr(args, 'api_key'))
