import json

def convert_to_chat_format(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            data = json.loads(line.strip())
            
            chat_format = {
                "messages": [
                    {
                        "role": "system",
                        "content": "You are a supportive and empathetic mental health chatbot. Provide helpful advice and coping strategies."
                    },
                    {
                        "role": "user",
                        "content": data["prompt"]
                    },
                    {
                        "role": "assistant",
                        "content": data["completion"]
                    }
                ]
            }
            
            json.dump(chat_format, outfile)
            outfile.write('\n')

# Usage
input_file = 'combined_dataset.json'  # Your input file name
output_file = 'chat_formatted_dataset.jsonl'  # Output file name

convert_to_chat_format(input_file, output_file)
print(f"Conversion complete. Output saved to {output_file}")