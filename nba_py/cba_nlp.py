import matplotlib.pyplot as plt
import spacy
import sys

from collections import Counter
from wordcloud import WordCloud

def main():
	league = sys.argv[1]
	n_words = int(sys.argv[2])
	league_list = ['mlb', 'nba', 'nfl', 'nhl', 'mls']
	if league not in league_list:
		print('Not an accepted league')
		exit()
		
	# /Users/fordhiggins/basketball/analytics/data/cba_files

	with open(f'/Users/fordhiggins/basketball/analytics/data/cba_files/{league}_cba.txt', 'r') as f:
		txt = f.read()

	words = ' '.join(txt.split())

	nlp = spacy.load('en')
	nlp.max_length = 1500000

	doc = nlp(words)
	lemmas = [token.lemma_ for token in doc if not token.is_stop 
		and not token.is_punct]

	ctr = Counter(lemmas)
	wtups = ctr.most_common(n_words)
	wdict = dict(wtups)

	wordcloud = WordCloud(background_color='red', colormap='Blues')
	wordcloud.fit_words(wdict)

	fig=plt.figure(figsize=(8, 6))
	plt.imshow(wordcloud)
	plt.axis("off")
	plt.title(f'{n_words} Most Common Words in {league.upper()} CBA')
	plt.savefig(f'/Users/fordhiggins/basketball/analytics/results/viz/{league}_cba_wordcloud_{n_words}.png')
	plt.show()


if __name__ == '__main__':
	main()