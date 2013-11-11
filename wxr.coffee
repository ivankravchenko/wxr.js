_ = require "underscore"
xml = require "xmlbuilder"

module.exports = (site) ->
	addPost = (post) ->
		node = channel
			.ele("item")
				.ele("wp:post_type", post.type or "post").up()
				.ele("wp:status", post.status or "publish").up()
				.ele("pubDate", post.pubDate).up()
				.ele("wp:post_date", post.pubDate).up()
				.ele("wp:post_date_gmt", post.pubDate).up()
		node.ele("wp:post_name").dat(post.slug) if post.slug
		node.ele("title").dat(post.title)
				
		node.ele("dc:creator", post.author) if post.author
		node.ele("description").dat(post.description) if post.description
		node.ele("content:encoded").dat(post.content) if post.content

		if post.categories
			for tag in post.tags
				node.ele "category",
					nicename: cat.name
					domain: "category"

		if post.tags
			for tag in post.tags
				node.ele "category",
					nicename: cat.name
					domain: "post_tag"

		if post.taxonomies
			for taxonomy in post.taxonomies
				node.ele "category",
					nicename: taxonomy.slug
					domain: taxonomy.domain

		if post.meta
			for k, v of post.meta
				if _.isArray v
					for _v in v
						node.ele("wp:postmeta")
							.ele("wp:meta_key").dat(k).up()
							.ele("wp:meta_value").dat(_v).up()
				else
					node.ele("wp:postmeta")
						.ele("wp:meta_key").dat(k).up()
						.ele("wp:meta_value").dat(v).up()

	addCat = (cat) ->
		return if not cat
		channel.ele("wp:category")
			.ele("wp:category_nicename", cat.slug).up()
			.ele("wp:cat_name").dat(cat.name).up()
	addTag = (tag) ->
		return if not tag
		channel.ele("wp:tag")
			.ele("wp:tag_slug", tag.slug).up()
			.ele("wp:tag_name").dat(tag.name).up()
	addedTaxes = []
	addTax = (tax) ->
		return if not tax or tax.slug in addedTaxes
		addedTaxes.push tax.slug
		channel.ele("wp:term")
			.ele("wp:term_taxonomy").dat(tax.domain).up()
			.ele("wp:term_slug", tax.slug).up()
			.ele("wp:term_name").dat(tax.name).up()
	
	doc = xml.create "rss", version: "1.0", encoding: "UTF-8"
	doc.att "version", "2.0"
	doc.att "xmlns:excerpt", "http://wordpress.org/export/1.2/excerpt/"
	doc.att "xmlns:content", "http://purl.org/rss/1.0/modules/content/"
	doc.att "xmlns:wfw", "http://wellformedweb.org/CommentAPI/"
	doc.att "xmlns:dc", "http://purl.org/dc/elements/1.1/"
	doc.att "xmlns:wp", "http://wordpress.org/export/1.2/"

	channel = doc.ele("channel")
		.ele("wp:wxr_version", "1.2").up()
		.ele("generator", "wxr.js").up()

	channel.ele("title").dat(site.title) if site.title
	channel.ele("description").dat(site.description) if site.description

	_.each(_.uniq(_.flatten(_.pluck site.posts, "categories"), "slug"), addCat)
	_.each(_.uniq(_.flatten(_.pluck site.posts, "tags"), "slug"), addTag)
	_.each(_.uniq(_.flatten(_.pluck site.posts, "taxonomies"), "slug"), addTax)
	
	_.each site.posts, addPost if site.posts
	doc.end()
	doc.toString pretty: true
