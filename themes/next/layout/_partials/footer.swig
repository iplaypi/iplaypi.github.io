<div class="copyright">{#
#}{% set current = date(Date.now(), "YYYY") %}{#
#}&copy; {% if theme.footer.since and theme.footer.since != current %}{{ theme.footer.since }}&ndash;{% endif %}{#
#}<span itemprop="copyrightYear">{{ current }}</span>
  <span class="post-meta-divider">|</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.footer.icon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">{{ theme.footer.copyright || config.author }}</span>

  {# 全站字数统计 #}
  {% if theme.post_wordcount.totalcount %}
    <span class="post-meta-divider">|</span>
    <span class="post-meta-item-icon">
      <i class="fa fa-area-chart"></i>
    </span>
    {% if theme.post_wordcount.item_text %}
      <span class="post-meta-item-text">{{ __('post.totalcount') }}</span>
    {% endif %}
    <span title="{{ __('post.totalcount') }}">{#
    #}{{ totalcount(site, '0,0.0a') }} 字{#
  #}</span>
  {% endif %}
</div>

{% if theme.footer.powered %}
  <div class="powered-by">{#反垃圾链接 rel="external nofollow"
  #}{{ __('footer.powered', '<a class="theme-link" target="_blank" href="https://hexo.io" rel="external nofollow">Hexo</a>') }}{#
#}</div>
{% endif %}

{% if theme.footer.powered and theme.footer.theme.enable %}
  <span class="post-meta-divider">|</span>
{% endif %}

{% if theme.footer.theme.enable %}
  <div class="theme-info">{#
  #}{{ __('footer.theme') }}&nbsp;{#反垃圾链接
  #}<a class="theme-link" target="_blank" href="https://github.com/iissnan/hexo-theme-next" rel="external nofollow">{#
    #}NexT.{{ theme.scheme }}{#
  #}</a>{% if theme.footer.theme.version %} v{{ theme.version }}{% endif %}{#
  #}
  {#添加页面底部统计信息在一行
  #}
    <script async src="//busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js"></script>
    <span id="busuanzi_container_site_pv" style='display:none'><span class="post-meta-divider">|</span> 总访问量 <span id="busuanzi_value_site_pv"></span> 次 
    </span>
    <span id="busuanzi_container_site_uv" style='display:none'><span class="post-meta-divider">|</span> 总访客 <span id="busuanzi_value_site_uv"></span> 人</span>
  </div>
{% endif %}

{# 添加页面底部统计信息,放在上面了 
<div>
<script async src="//busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js"></script>
<span id="busuanzi_container_site_pv" style='display:none'>总访问量 <span id="busuanzi_value_site_pv"></span> 次 <span class="post-meta-divider">|</span>
</span>
<span id="busuanzi_container_site_uv" style='display:none'> 总访客 <span id="busuanzi_value_site_uv"></span> 人</span>
</div>
#}

{% if theme.footer.custom_text %}
  <div class="footer-custom">{#
  #}{{ theme.footer.custom_text }}{#
#}</div>
{% endif %}
