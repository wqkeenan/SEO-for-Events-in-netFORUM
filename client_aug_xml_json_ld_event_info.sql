USE [nfAAAATEST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*---------------------------------------------------------------------
	Author:			William Keenan
	Create date:	September 12, 2015
	Description:	XML events info detail for JSON+LD page details 

	EXECUTE client_aug_xml_json_ld_event_info 
		@evt_key = '7099868b-8147-4b83-8894-39ea60d616e0', -- STRATFEST 2015
		@HttpServerPath = 'https://amstest.aaaa.org/eweb'

---------------------------------------------------------------------*/
ALTER PROCEDURE [dbo].[client_aug_xml_json_ld_event_info]
	@evt_key			varchar(38) = NULL,
	@HttpServerPath		varchar(400) = NULL

AS
BEGIN

	DECLARE @now datetime
	DECLARE @today datetime
	DECLARE @cms_page_uri varchar(400)

	SET @now = getdate()
	SET @today = dbo.av_begin_of_day(@now)
	SET @cms_page_uri = '/content.aspx?webcode=EventInfo&Reg_evt_key='

	SELECT
		(
		SELECT 
			[@itemtype] = 'Event',
			[@xml:id] = evt_key,
			[evt_title/@itemprop] = 'name',
			[evt_title] = evt_title,
			(
			SELECT 
				[@xml:href] = ISNULL(evt_event_url, @HttpServerPath + @cms_page_uri + CONVERT(varchar(36),evt_key)),
				[@itemprop] = 'url',
				[text()] = ISNULL(evt_title+' ','') + 'Website'
			WHERE evt_event_url IS NOT NULL
			FOR XML PATH('evt_event_url'), TYPE
			),
			(
			SELECT 
				[@itemprop] = 'startDate', 
				[@datetime] = [dbo].[av_DatePlusTimeToDateTime](evt_start_date,ISNULL(evt_start_time,'8:30 AM')),
				[text()] = [dbo].[av_DatePlusTimeToDateTime](evt_start_date,ISNULL(evt_start_time,'8:30 AM'))
			WHERE evt_start_date IS NOT NULL 
			FOR XML PATH ('evt_start_datetime'), TYPE
			),
			(
			SELECT 
				[@itemprop] = 'endDate', 
				[@datetime] = [dbo].[av_DatePlusTimeToDateTime](evt_end_date,evt_end_time),
				[text()] = [dbo].[av_DatePlusTimeToDateTime](evt_end_date,evt_end_time)
			WHERE [dbo].[client_4as_normalize_space](evt_end_date) IS NOT NULL 
			FOR XML PATH ('evt_end_datetime'), TYPE
			),	
			[eventStatus/@itemprop] = 'eventStatus', 
			[eventStatus] = 'EventScheduled',
			(
			SELECT
				[@xml:id] = loc_key,
				[@itemprop] = 'location',
				[@itemtype] = 'Place',
				[loc_name/@itemprop] = 'name', 
				[loc_name] = ISNULL(loc_display_name_ext,loc_name),
				(
				SELECT 
					[@xml:id] = url_key,
					[@xml:href] = url_code,
					[@itemprop] = 'url',
					[text()] = url_code
				FROM co_website WITH (NOLOCK) 
				WHERE loc_url_key = url_key 
					AND url_code IS NOT NULL
					AND url_delete_flag = 0
				FOR XML PATH('url_code'), TYPE
				),
				(
				SELECT
					[@xml:id] = adr_key,
					[@itemprop] = 'address',
					[@itemtype] = 'PostalAddress',
					[streetAddress/@itemprop] = 'streetAddress',
					[streetAddress] = ISNULL(adr_line1 + ' ', '') + ISNULL(adr_line2 + ' ', '') + ISNULL(adr_line3, ''), 
					(SELECT 'addressLocality' AS [@itemprop], adr_city AS [text()] WHERE adr_city IS NOT NULL FOR XML PATH('adr_city'), TYPE ),
					(SELECT 'addressRegion' AS [@itemprop], adr_state AS [text()] WHERE adr_state IS NOT NULL FOR XML PATH('adr_state'), TYPE ),
					(SELECT 'postalCode' AS [@itemprop], adr_post_code AS [text()] WHERE adr_post_code IS NOT NULL FOR XML PATH('adr_post_code'), TYPE ),
					(SELECT 'addressCountry' AS [@itemprop], adr_country AS [text()] WHERE adr_country IS NOT NULL FOR XML PATH('adr_country'), TYPE ),
					(
					SELECT
						[@itemprop] = 'geo',
						[@itemtype] = 'GeoCoordinates',
						(SELECT [@itemprop] = 'latitude', [text()] = CAST([adr_latitude] AS decimal(19,10)) FOR XML PATH('adr_latitude'), TYPE ),
						(SELECT [@itemprop] = 'longitude', [text()] = CAST([adr_longitude] AS decimal(19,10)) FOR XML PATH('adr_longitude'), TYPE )
					WHERE [adr_latitude] IS NOT NULL AND [adr_longitude] IS NOT NULL
					FOR XML PATH ('geo'), TYPE
					)
				FROM co_customer_x_address WITH (NOLOCK) 
					JOIN co_address WITH (NOLOCK) ON cxa_adr_key = adr_key AND adr_delete_flag = 0 
				WHERE loc_cxa_key = cxa_key 
					AND cxa_delete_flag = 0 
					AND etp_key != 'be0f508c-a2c0-467e-b3f6-6cc873c1d620' -- no address for webinars
				FOR XML PATH ('address'), ROOT('addresses'), TYPE
				)
			FROM ev_event_location WITH (NOLOCK)
				JOIN ev_location WITH (NOLOCK) ON evl_loc_key = loc_key
					JOIN ev_location_ext WITH  (NOLOCK) ON loc_key = loc_key_ext
			WHERE evl_evt_key = evt_key
				AND (evl_primary=1 OR (SELECT COUNT(*) FROM ev_event_location WHERE evl_evt_key=evt_key)= 1)
			FOR XML PATH ('location'), ROOT('locations'), TYPE
			),
			(
			SELECT
				(
				SELECT TOP 1
					[@itemprop] = 'offers',
					[@itemtype] = 'Offer',
					[category/@itemprop] = 'category',
					[category/@content] = 'primary',
					[availability/@itemprop] = 'availability',
					[availability] = CASE 
						WHEN vev_evt_capacity IS NULL THEN 'InStock'
						WHEN vev_remaining < 1 THEN 'SoldOut'
						WHEN vev_remaining < ISNULL(vev_evt_capacity,99999)/10 THEN 'LimitedAvailability'
						ELSE 'InStock'
					END,
					[price/@itemprop] = 'price',
					[price/@content] = prc_price,
					[price] = prc_price,
					[priceCurrency/@itemprop] = 'priceCurrency',
					[priceCurrency/@content] = 'USD',
					[priceCurrency] = '$',
					[url/@itemprop] = 'url',
					[url] = @HttpServerPath + @cms_page_uri + CONVERT(varchar(36),evt_key)
				FROM oe_price_attribute WITH (NOLOCK) 
					JOIN oe_price WITH (NOLOCK) 
							ON prc_delete_flag = 0
							AND pat_prc_key = prc_key
							AND prc_sell_online = 1
							AND (pat_default_flag = 1
								OR dbo.DateRangeCompare(prc_start_date, prc_end_date, evt_start_date, evt_start_date, @today) = 1 
								)
						JOIN oe_product WITH (NOLOCK) 
								ON prd_delete_flag = 0 
								AND prd_key = prc_prd_key
								AND prd_sell_online = 1
								AND (pat_default_flag = 1
									OR dbo.DateRangeCompare(prd_start_date, prd_end_date, evt_start_date, evt_start_date, @today) = 1 
									)
							JOIN ev_event_fee WITH (NOLOCK) 
									ON fee_delete_flag = 0 
									AND prd_key = fee_prd_key
									AND fee_evt_key = evt_key
				WHERE pat_delete_flag = 0
					AND (pat_default_flag = 1
						OR dbo.DateRangeCompare(pat_start_date, pat_end_date, evt_start_date, evt_start_date, @today) = 1 
						)
				ORDER BY prc_price
				FOR XML PATH ('offer'), TYPE
				)
			FOR XML PATH ('offers'), TYPE
			)
		FROM ev_event WITH (NOLOCK)  
			JOIN ev_event_ext WITH (NOLOCK) ON evt_key = evt_key_ext 
			LEFT JOIN ev_event_type WITH (NOLOCK) ON evt_etp_key = etp_key
				LEFT JOIN ev_event_type_ext WITH (NOLOCK) ON etp_key = etp_key_ext
			LEFT JOIN ev_event_category WITH (NOLOCK) ON evt_etc_key = etc_key
			LEFT JOIN fw_time_zone WITH (NOLOCK) ON evt_tzn_key = tzn_key
			JOIN vw_ev_event_summary WITH (NOLOCK) ON vev_evt_key = evt_key
		WHERE evt_delete_flag = 0
			AND evt_key = @evt_key
		FOR XML PATH ('event'), TYPE
		)
	FOR XML PATH ('events')


END


GO


